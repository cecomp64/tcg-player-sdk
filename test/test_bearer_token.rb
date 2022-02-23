require 'test_helper'

class BearerTokenTest < Minitest::Test
  # Check that the expected methods are accessible
  def test_api
    bt = TCGPlayerAPI::BearerToken.new('.issued' => DateTime.now.to_s, '.expires' => DateTime.now.to_s)
    [:token, :expiration, :expires_in, :issued].each do |method|
      assert_equal bt.respond_to?(method), true
    end
  end
end
