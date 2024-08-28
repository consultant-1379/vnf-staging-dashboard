require 'httparty'

class Jenkins
  class << Jenkins
    def release_from_ecm_artifacts_file(url)
      begin
        auth = {username: ENV['DASHBOARD_USER'], password: ENV['DASHBOARD_PASSWORD']}
        response = HTTParty.get("#{url}/artifact/artifact.properties/*view*/", basic_auth: auth)
        return response
      rescue => e
        raise JenkinsConnectionException, "Could not get artifacts file from Jenkins #{full_url}, details: #{e}"
      end
    end

    def release_from_lcm_artifacts_file(url)
      begin
        auth = {username: ENV['DASHBOARD_USER'], password: ENV['DASHBOARD_PASSWORD']}
        response = HTTParty.get("#{url}/artifact/propertiesFile.txt/*view*/", basic_auth: auth)
        return response
      rescue => e
        raise JenkinsConnectionException, "Could not get artifacts file from Jenkins #{full_url}, details: #{e}"
      end
    end

    def release_from_so_artifacts_file(url)
      begin
        auth = {username: ENV['DASHBOARD_USER'], password: ENV['DASHBOARD_PASSWORD']}
        response = HTTParty.get("#{url}/artifact/infrastructure/autodeploy-to-eo-mt/artifacts.properties/*view*/", basic_auth: auth)
        return response
      rescue => e
        raise JenkinsConnectionException, "Could not get artifacts file from Jenkins #{full_url}, details: #{e}"
      end
    end
  end
end