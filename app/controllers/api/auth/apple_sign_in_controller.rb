module API
  module Auth
    class AppleSignInController < ApplicationController
      skip_before_action :authenticate_user!

      def create
        token = params[:id_token]
        raise "Missing token" if token.blank?

        payload = verify_apple_token(token)
        apple_user_id = payload["sub"]
        email = payload["email"]
        timezone = params[:timezone] || "UTC"

        user = find_or_create_apple_user(apple_user_id, email, timezone)

        sign_in(user, store: false)
        auth_headers = user.create_new_auth_token
        response.headers.merge!(auth_headers)

        render json: {
          success: true,
          user: user.slice(:id, :email, :provider, :uid, :timezone),
          message: "Successfully signed in with Apple"
        }, status: :ok
      rescue JWT::DecodeError => e
        render json: { error: "Invalid Apple token: #{e.message}" }, status: :unauthorized
      rescue StandardError => e
        Rails.logger.error "Apple Sign In Error: #{e.message}"
        render json: { error: "Authentication failed" }, status: :unauthorized
      end

      private

      def verify_apple_token(id_token)
        # Cache Apple's public keys for better performance
        jwks = Rails.cache.fetch("apple_jwks", expires_in: 1.hour) do
          jwks_uri = URI("https://appleid.apple.com/auth/keys")
          response = fetch_with_ssl(jwks_uri)
          raise "Failed to fetch Apple keys" unless response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        end

        jwk_set = JWT::JWK::Set.new(jwks)

        # Decode and verify token with proper audience validation
        decoded_token = JWT.decode(
          id_token,
          nil,
          true,
          {
            jwks: jwk_set,
            algorithms: ["RS256"],
            iss: "https://appleid.apple.com",
            verify_iss: true,
            aud: bundle_identifier,
            verify_aud: true,
            verify_exp: true,
            verify_iat: true
          }
        ).first

        # Validate required claims
        validate_token_claims(decoded_token)

        decoded_token
      end

      def validate_token_claims(payload)
        raise JWT::InvalidPayload, "Missing sub claim" unless payload["sub"].present?
        raise JWT::InvalidPayload, "Invalid auth_time" if payload["auth_time"] && payload["auth_time"] > Time.current.to_i

        # Validate nonce if your app uses it
        if params[:nonce].present? && payload["nonce"] != params[:nonce]
          raise JWT::InvalidPayload, "Nonce mismatch"
        end
      end

      def bundle_identifier
        # Support multiple bundle identifiers for different environments
        identifier = ENV["APPLE_BUNDLE_IDENTIFIER"] || ENV["CONCEPTS_BUNDLE_IDENTIFIER"] || "com.ygg0f.concepts"
        raise "Apple bundle identifier not configured" if identifier.blank?
        identifier
      end

      def generate_placeholder_email(apple_user_id)
        "apple_#{apple_user_id}@#{Rails.application.class.module_parent_name.downcase}.local"
      end

      def fetch_with_ssl(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        # Disable CRL checking which can fail in some environments
        http.verify_callback = ->(preverify_ok, store_context) {
          # Accept if basic verification passed, even if CRL check failed
          return true if preverify_ok

          # Allow CRL-related errors (error codes 3 and 4)
          error = store_context.error
          crl_errors = [
            OpenSSL::X509::V_ERR_UNABLE_TO_GET_CRL,
            OpenSSL::X509::V_ERR_CRL_NOT_YET_VALID,
            OpenSSL::X509::V_ERR_CRL_HAS_EXPIRED
          ]
          crl_errors.include?(error)
        }

        request = Net::HTTP::Get.new(uri.request_uri)
        http.request(request)
      end

      def find_or_create_apple_user(apple_user_id, email, timezone = "UTC")
        user = User.find_by(provider: "apple", uid: apple_user_id)

        if user
          user.update!(email: email) if email.present? && user.email != email
          user.update!(timezone: timezone) if timezone.present? && user.timezone != timezone
          return user
        end

        if email.present?
          existing_user = User.find_by(email: email)
          if existing_user
            existing_user.update!(provider: "apple", uid: apple_user_id, timezone: timezone)
            return existing_user
          end
        end

        User.create!(
          provider: "apple",
          uid: apple_user_id,
          email: email.presence || generate_placeholder_email(apple_user_id),
          password: SecureRandom.hex(16),
          confirmed_at: Time.current,
          timezone: timezone
        )
      end
    end
  end
end
