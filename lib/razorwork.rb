# frozen_string_literal: true

# RazorWork helps keep your razor-server configurations synchronised with the
# server. Store your polices/tags etc. in yaml files and run this gem after
# each change.
module RazorWork
    def self.setup
        require 'rest-client'
        require 'json'
        require 'yaml'
        require_relative 'razorwork/tags.rb'
  
        razor_server = 'razor-test.mps.lan'
  
        # TODO: add proper exception handling and logging
        # TODO: make modules autodiscover allowed_update_fields
  
        ## Create global refs to api endpoints.
        resp = $client.get("http://#{razor_server}:8150/api")
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
end

RazorWork.setup
Tags.sync