require 'test_helper'

class TCGPlayerAPITest < Minitest::Test
  include TCGApiFactory

  attr_accessor :tcg

  ##
  # This test requires a valid API key
  def test_authorize
    tcg = TCGPlayerAPI.new
    tcg.authorize

    refute_equal tcg.bearer_token, nil
    assert_equal tcg.bearer_token.expired?, false
  end

  def test_invalid_bearer_token_response
    VCR.use_cassette('test_invalid_bearer_token_response') do
      tcg = TCGPlayerAPI.new(bearer_token: invalid_bearer_token, noretry: true)
      response = tcg.product_pricing(83543)

      # Check that there is one error, and that it is about the bearer token
      assert_equal response.success, false
      assert_equal response.errors.size, 1
      refute_equal response.errors.first =~ /bearer token/, nil
    end
  end

  ##
  # This test requires a valid API key
  def test_retry_with_invalid_bearer_token
    tcg = TCGPlayerAPI.new(bearer_token: invalid_bearer_token)
    response = tcg.product_pricing(83543)

    assert_equal response.success, true
    assert_equal response.errors.size, 0
  end
end
