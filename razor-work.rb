#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'yaml'

razor_server = "razor-test"



# Create friendly refs to endpoints.
resp = RestClient.get("http://#{razor_server}:8150/api")
api_root = body = JSON.parse(resp.body)

command_urls = Hash.new
api_root["commands"].each do |c|
    command_urls[c["name"]] = c["id"]
end

collection_urls = Hash.new
api_root["collections"].each do |c|
    collection_urls[c["name"]] = c["id"]
end


