require 'minitest/autorun'
require 'tcg-player-sdk'
require 'webmock/minitest'
require 'vcr'
require_relative 'tcg_api_factory'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures"
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end