require 'tcg-player-sdk'

module TCGApiFactory

  BEARER_TOKEN_FILE = './test/bearer_token.json'

  ##
  # Creates an expired and jibberish bearer token
  #
  # @return TCGPlayerSDK::BerarerToken
  def invalid_bearer_token
    @invalid_bearer_token ||= TCGPlayerSDK::BearerToken.new('access_token'=> 'fff1234', '.issued' => DateTime.now.to_s, '.expires' => DateTime.now.to_s)
  end

  ##
  # Return the bearer token that was used in VCR fixture generation.  Whenever this changes, most VCR recordings need
  # to be regenerated.
  #
  # @return TCGPlayerSDK::BerarerToken
  def valid_bearer_token
    hash = JSON.parse(File.read(BEARER_TOKEN_FILE))
    TCGPlayerSDK::BearerToken.new(hash)
  end
end
