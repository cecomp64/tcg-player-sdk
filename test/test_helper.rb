require 'minitest/autorun'
require 'tcg-player-api'
require 'webmock/minitest'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures"
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end

module TCGApiFactory
  ##
  # Creates an expired and jibberish bearer token
  #
  # @return TCGPlayerAPI::BerarerToken
  def invalid_bearer_token
    @invalid_bearer_token ||= TCGPlayerAPI::BearerToken.new('access_token'=> 'fff1234', '.issued' => DateTime.now.to_s, '.expires' => DateTime.now.to_s)
  end

  ##
  # Return the bearer token that was used in VCR fixture generation
  #
  # @return TCGPlayerAPI::BerarerToken
  def valid_bearer_token
  end
end