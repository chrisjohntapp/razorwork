# frozen_string_literal: true

# RazorWork helps keep your razor-server configurations synchronised with the
# server. Store your polices/tags etc. in yaml files and run this gem after
# each change.
require 'rest-client'
require 'json'
require 'yaml'
require 'logger'
require_relative 'razorwork/tag.rb'

# Configuration.
RAZOR_SERVER = 'razorserver'

# TODO: add proper exception handling and logging.
# TODO: make modules autodiscover allowed_update_fields.
# TODO: set configuration elements via CLI arguments.

# Main module definition.
module RazorWork
    # Setup.
    def self.setup
        # Create global refs to api endpoints.
        resp = RestClient.get("http://#{RAZOR_SERVER}:8150/api")
        api_root = JSON.parse(resp.body)

        $command_urls = {}
        api_root['commands'].each do |c|
            $command_urls[c['name']] = c['id']
        end

        $collection_urls = {}
        api_root['collections'].each do |c|
            $collection_urls[c['name']] = c['id']
        end
    end

    def self.log
        if @logger.nil?
            @logger = Logger.new STDOUT
            @logger.level = Logger::DEBUG
            @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
        end
        @logger
    end
end

module RazorError
    # Razor error(s).
    class APIError < StandardError
        def initialize(msg='Interaction with the razor API failed.')
            super
        end
    end

    # Razor error(s).
    class APILimitation < StandardError
        def initialize(msg='Action not allowed by razor API.')
            super
        end
    end
end
