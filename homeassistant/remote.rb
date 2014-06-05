# * Provides classes to interface with a Home Assistant instance

require 'net/http'
require 'json'

require_relative 'error'

# Class to interface with a Home Assistant instance via API-calls.
class HomeAssistantAPI
    @@no_on_error_value_given = Object.new()

    def initialize(host, password, port=8123)
        @baseuri = "http://%s:%s/api/" % [host, port]
        @host = host
        @password = password
        @port = port
        @valid = nil
    end

    # Tests if the API is valid.
    def is_valid?(force_refresh=false)
        if @valid.nil? or force_refresh
            begin
                call_api("")
                @valid = true
            rescue HomeAssistantError
                @valid = false
            end
        end

        return @valid
    end

    # Queries the API for all the states.
    def states()
        return call_api("states", value_on_error: {})
    end

    # Queries the API for the state of a specific entity_id.
    def get_state(entity_id)
        return call_api('states/'+entity_id, value_on_error: nil)
    end

    def set_state(entity_id, state, attributes: nil)
        data = {:new_state => state}

        if attributes
            data[:attributes] = JSON::generate(attributes)
        end

        return call_api('states/'+entity_id, 'POST', data, value_on_error: nil)
    end

    # Queries the API for which events are being listend for.
    def events()
        return call_api("events", value_on_error: {})
    end

    # Fires an event at the API.
    def fire_event(event_type, event_data: nil)
        data = event_data.nil? ? nil : {:event_data => JSON::generate(event_data)}

        return call_api('event/'+event_type, 'POST', data, value_on_error: nil)
    end

    # Queries the API for registered services.
    def services()
        return call_api("services", value_on_error: {})
    end

    # Generic method to make a call to the API.
    def call_api(path, method:'GET', data: nil, value_on_error: @@no_on_error_value_given)
        uri = URI(@baseuri + path)

        if data
            data[:api_password] = @password
        else
            data = {:api_password => @password }
        end

        begin
            if method == 'GET'
                uri.query = URI.encode_www_form(data)

                res = Net::HTTP.get_response(uri)
            else
                res = Net::HTTP.post_form(uri, data)
            end

            if res.is_a?(Net::HTTPSuccess)
                return JSON.parse(res.body)
            elsif value_on_error != @@no_on_error_value_given
                return value_on_error
            else
                raise HomeAssistantError, "Error communicating with the API"
            end

        rescue EOFError
            if value_on_error != @@no_on_error_value_given
                return value_on_error
            else
                raise HomeAssistantError, "Error reaching API"
            end            

        
        rescue JSON::JSONError
            if value_on_error != @@no_on_error_value_given
                return value_on_error
            else
                raise HomeAssistantError, "Error parsing API response"
            end

        end

    end
end
