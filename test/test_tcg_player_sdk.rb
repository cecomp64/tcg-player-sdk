require 'test_helper'

class TCGPlayerAPITest < Minitest::Test
  include TCGApiFactory

  attr_accessor :tcg

  ##
  # This test requires a valid API key
  def test_authorize
    tcg = TCGPlayerSDK.new
    tcg.authorize

    refute_equal tcg.bearer_token, nil
    assert_equal tcg.bearer_token.expired?, false
  end

  def test_invalid_bearer_token_response
    VCR.use_cassette('test_invalid_bearer_token_response') do
      tcg = TCGPlayerSDK.new(bearer_token: invalid_bearer_token, noretry: true)
      response = tcg.product_pricing(83543).response

      # Check that there is one error, and that it is about the bearer token
      assert_equal response.success, false
      assert_equal response.errors.size, 1
      refute_equal response.errors.first =~ /bearer token/, nil
    end
  end

  ##
  # This test requires a valid API key
  def test_retry_with_invalid_bearer_token
    tcg = TCGPlayerSDK.new(bearer_token: invalid_bearer_token)
    sample_successful_query(tcg)
  end

  ##
  # This test requires a valid API key
  def test_query_without_authorize
    tcg = TCGPlayerSDK.new
    sample_successful_query(tcg)
  end

  def test_product_price
    VCR.use_cassette('test_product_price') do
      ids = [85737, 85736]
      tcg = TCGPlayerSDK.new(bearer_token: valid_bearer_token)
      pl = tcg.product_pricing(ids)

      assert_instance_of TCGPlayerSDK::ProductPriceList, pl

      assert_equal pl.prices.keys.size, 2
      refute_nil pl.response

      pl.prices.each do |key, ppl|
        assert_includes ids, key

        ppl.each do |pp|
          assert_instance_of TCGPlayerSDK::ProductPrice, pp
          assert_kind_of TCGPlayerSDK::ResponseStruct, pp
        end
      end

      normal_price = pl.prices.values.flatten.select{|pp| pp.subTypeName == 'Normal'}.first

      refute_nil normal_price
      refute normal_price.has_valid_prices?

      holo_price = pl.prices.values.flatten.select{|pp| pp.subTypeName == 'Holofoil'}.first

      assert holo_price
      assert holo_price.has_valid_prices?

      pl.valid_prices.values.flatten.each do |valid_pr|
        assert valid_pr.has_valid_prices?
      end
    end
  end

  private
  def sample_successful_query(tcg)
    response = tcg.product_pricing(83543).response
    assert_equal response.success, true
    assert_equal response.errors.size, 0
  end
end
