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
  # Return the bearer token that was used in VCR fixture generation.  Whenever this changes, most VCR recordings need
  # to be regenerated.
  #
  # @return TCGPlayerAPI::BerarerToken
  def valid_bearer_token
    hash = JSON.parse('{"access_token":"6Qf-Gzp38teiDEgYC0lekuMHyMMBu9m0d4DvHfYYOp640dp-Li6JT5oRjcTcKIUi_bdw1oRPOWRDsE3ixvMJcJ5n4V-U4QVnb5NQoH7apEfC-8b-4889fE9KOtZ8WOa5N6gNAMUPY4x1g1ugAx226Nw0L05nzJR1GwG07xGdJqiArX1Mm8OG6roA4VHANNsVFqnvfttrqkbN1ddqA1ttCTPVi1-EaYS4Erlsa4NXDfv57fmBfD3b65WDi3YOjQE-syIW5eRirXg1hhU4fkIx_r2r7KPdvKBQZI2mmfetfe-nJmL62NK48RofYZTcxm4AizJSpQ","token_type":"bearer","expires_in":1209599,"userName":"5a3fbd82-2e45-488e-820f-6a69996320ac",".issued":"Wed, 23 Feb 2022 23:31:29 GMT",".expires":"Wed, 09 Mar 2022 23:31:29 GMT"}')
    TCGPlayerAPI::BearerToken.new(hash)
  end
end