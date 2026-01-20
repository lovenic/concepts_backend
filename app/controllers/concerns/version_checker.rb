module VersionChecker
  extend ActiveSupport::Concern

  included do
    after_action :set_min_version_header
  end

  private

  def app_versions_config
    @app_versions_config ||= YAML.load_file(Rails.root.join("config", "app_versions.yml"))
  end

  def min_app_version
    app_versions_config["min_ios_version"]
  end

  def set_min_version_header
    response.headers["X-Min-App-Version"] = min_app_version
  end

  def app_version_outdated?
    mobile_app_version_lt?(min_app_version)
  end

  def mobile_app_version
    @mobile_app_version ||= begin
      version_string = request.headers["X-App-Version"]
      version_string ? Gem::Version.new(version_string) : nil
    rescue ArgumentError
      # Handle invalid version strings gracefully
      nil
    end
  end

  def mobile_app_version_gte?(version_string)
    return false unless mobile_app_version

    mobile_app_version >= Gem::Version.new(version_string)
  end

  def mobile_app_version_lt?(version_string)
    return true unless mobile_app_version

    mobile_app_version < Gem::Version.new(version_string)
  end

  def mobile_app_version_lte?(version_string)
    return true unless mobile_app_version

    mobile_app_version <= Gem::Version.new(version_string)
  end

  def mobile_app_version_gt?(version_string)
    return false unless mobile_app_version

    mobile_app_version > Gem::Version.new(version_string)
  end
end
