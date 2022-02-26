require 'test_helper'

class TCGPlayerAPITest < Minitest::Test
  include TCGApiFactory

  def test_sliced_prices
    VCR.use_cassette('test_sliced_prices') do
      # Buncha IDs
      tcg_ids = lots_of_ids
      tcg = TCGPlayerSDK.new(bearer_token: valid_bearer_token, noretry: true)
      pl = tcg.product_pricing(tcg_ids)

      assert pl.success
      assert pl.errors.empty?

      # Check valid_prices first to make sure it resolves any dependency on prices
      assert_equal pl.valid_prices.keys.size, tcg_ids.size
      assert_equal pl.prices.keys.size, tcg_ids.size
    end
  end

  # Should refactor this file as a "products" test file
  def test_sliced_details
    tcg_ids = lots_of_ids
    tcg = TCGPlayerSDK.new(bearer_token: valid_bearer_token, noretry: true)
    pd = tcg.product_details(tcg_ids)

    assert pd.success
    assert pd.errors.empty?
    assert_equal pd.results.size, tcg_ids.size
  end
end
