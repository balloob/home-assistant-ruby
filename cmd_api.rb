require 'pp'
require 'yaml'

require_relative 'homeassistant/remote'

# Load and validate config

config_filename = 'config_api.yaml'

if File.file? config_filename
    config = YAML.load_file(config_filename)

    if !config.is_a?(Hash)
        puts "Could not parse config file properly."
        exit()
    end

    missing = []

    for field in ['host', 'api_password']
        if !config.key? field
            missing.push field
        end
    end

    if ! missing.empty?
        puts "Invalid config file found."
        puts "Missing fields #{missing}"
        exit()
    end

    api = HomeAssistantAPI.new(config['host'], config['api_password'])

    if ! api.is_valid?
        puts "Attempt to validate API failed."
        exit()
    end

else
    puts "Config file #{config_filename} not found. Please create."
    puts "See #{config_filename}.example for an example."
    exit()    
end

# Check input and execute
valid_actions = ['states', 'services', 'events']

if ARGV.empty? or ! valid_actions.include? ARGV[0]
    puts "Specify action: #{valid_actions.join(', ')}"
    exit()
end

# Check what to do
case ARGV[0]
when "states"
    PP.pp api.states
when "services"
    PP.pp api.services
when "events"
    PP.pp api.events
end
