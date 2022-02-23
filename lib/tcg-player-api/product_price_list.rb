class TCGPlayerAPI::ProductPriceList
  attr_accessor :response

  ##
  # Group prices by product ID.  This will set
  # prices to an empty hash if there was an error.  Check response.errors for details about any errors.
  #
  # @param _response[TCGPlayerAPI::ResponseStruct] the result of calling TCGPlayerAPI#product_pricing
  def initialize(_response)
    @response = _response

    if(response.success && response.results)
      @prices = response.results.map{|r| TCGPlayerAPI::ProductPrice.new(r)}.group_by{|r| r.productId}
    else
      @prices = {}
    end
  end

  ##
  # Returns a hash with productIds as keys, and a list of prices with subtypes as values:
  #   {
  #     85736 => [
  #         {
  #                  "productId" => 85737,
  #                   "lowPrice" => 4.99,
  #                   "midPrice" => 5.63,
  #                  "highPrice" => 7.73,
  #                "marketPrice" => 10.35,
  #             "directLowPrice" => nil,
  #                "subTypeName" => "Reverse Holofoil"
  #         },
  #         {
  #                  "productId" => 85737,
  #                   "lowPrice" => nil,
  #                   "midPrice" => nil,
  #                  "highPrice" => nil,
  #                "marketPrice" => nil,
  #             "directLowPrice" => nil,
  #                "subTypeName" => "Unlimited Holofoil"
  #         },
  #     ]
  #   }
  #
  # @return [Hash<Integer, Array<TCGPlayerAPI::ProductPrice>>]
  def prices
    @prices
  end

  ##
  # Weed out any ProductPrice objects that have no valid prices.
  #
  # @return [Hash<Integer, Array<TCGPlayerAPI::ProductPrice>>]
  def valid_prices
    valid_prices = {}
    @prices.each do |id, prl|
      valid_prices[id] ||= []
      valid_prices[id] = prl.select{|pr| pr.has_valid_prices?}
    end

    return valid_prices
  end
end

# A wrapper around the ResponseStruct for an individual product subtype's price.
#         {
#                  "productId" => 85737,
#                   "lowPrice" => nil,
#                   "midPrice" => nil,
#                  "highPrice" => nil,
#                "marketPrice" => nil,
#             "directLowPrice" => nil,
#                "subTypeName" => "Unlimited Holofoil"
#         },
class TCGPlayerAPI::ProductPrice < TCGPlayerAPI::ResponseStruct
  def initialize(hash = nil)
    super
  end

  ##
  # @return [Boolean] Returns false if there are no non-nil prices
  def has_valid_prices?
    return !(lowPrice.nil? && midPrice.nil? && highPrice.nil? && directLowPrice.nil? && marketPrice.nil?)
  end
end
