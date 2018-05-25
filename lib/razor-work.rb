#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'
require 'razor-work/tags.rb'

razor_server = 'razor-test'
config_dir = '/var/local/razor-server'

# TODO: add proper exception handling and logging
# TODO: make modules autodiscover allowed_update_fields

## Create global refs to api endpoints.
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

## Synchronise tags.
Tags.sync

