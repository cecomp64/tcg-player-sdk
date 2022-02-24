require 'test_helper'

class BearerTokenTest < Minitest::Test
  include TCGApiFactory

  # Check that the expected methods are accessible
  def test_api
    bt = TCGPlayerSDK::BearerToken.new('.issued' => DateTime.now.to_s, '.expires' => DateTime.now.to_s)
    [:token, :expiration, :expires_in, :issued].each do |method|
      assert_equal bt.respond_to?(method), true
    end
  end

  def test_expiration
    assert_equal invalid_bearer_token.expired?, true
  end
end
