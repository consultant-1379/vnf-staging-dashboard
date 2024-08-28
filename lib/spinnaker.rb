require 'httparty'

class Spinnaker
  class << Spinnaker
    def source_json(spinnaker_url)
      begin
        auth = {username: ENV['DASHBOARD_USER'], password: ENV['DASHBOARD_PASSWORD']}
        response = HTTParty.get(spinnaker_url, basic_auth: auth)
        return response
      rescue => e
        raise SpinnakerConnectionException, "No response from Spinnaker #{spinnaker_url}, details: #{e}"
      end
    end
  end
end

class SpinnakerConnectionException < StandardError
end