#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'
# require './tags.rb'

razor_server = 'razor-test'
config_dir = '/var/local/razor-server'

# TODO: check for correct dir structure
# TODO: add proper exception handling and logging

# Create friendly refs to api endpoints.
resp = RestClient.get("http://#{razor_server}:8150/api")
api_root = JSON.parse(resp.body)

$command_urls = Hash.new
api_root["commands"].each do |c|
    $command_urls[c["name"]] = c["id"]
end

$collection_urls = Hash.new
api_root["collections"].each do |c|
    $collection_urls[c["name"]] = c["id"]
end

module Tags
    def self.check_tag_exists(tag_name)
        all_tags = JSON.parse(RestClient.get($collection_urls['tags']))
        all_tags['items'].each do |item|
            if item.has_key?('name') && item['name'] == name
                return true
            else
                return false
            end
        end
    end

    def self.check_tag_fields_updatable(tag_name, desired_config)
        # Get current config & drop unused keys.
        current_config = JSON.parse(RestClient.get("#{$collection_urls['tags']}/#{tag_name}"))
        ['id', 'spec'].each { |i| current_config.delete(i) }
        
        # Get list of elements to change.
        # list keys present in both hashes 
        # check which ones are different
        
        # Check against list of 'unchangeable' elements.
    end

end

def sync_tags

    basedir = config_dir
    tag_files = Dir.glob("tags/*.json")

    # Load desired config and extract tag name.
    tag_files.each do |t|
        tag_config = YAML.load_file(t)
        tag_name = tag_config['name']

        # Either update existing tag (if possible) or create new tag. 
        if Tags.check_tag_exists(tag_name)
            if Tags.check_tag_fields_updatable(tag_name, tag_config)
                # update tag # TODO
            else
                # error: unsupported operation
            end
        else
            # create tag #
        end 
    end
end
