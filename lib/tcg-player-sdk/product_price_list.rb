class TCGPlayerSDK::ProductPriceList < TCGPlayerSDK::ResponseStruct

  def initialize(hash = {})
    super
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
  # @return [Hash<Integer, Array<TCGPlayerSDK::ProductPrice>>]
  def prices
    if(self.success && self.results)
      @prices ||= self.results.map{|r| TCGPlayerSDK::ProductPrice.new(r)}.group_by{|r| r.productId}
    else
      @prices = {}
    end

    @prices
  end

  ##
  # Weed out any ProductPrice objects that have no valid prices.
  #
  # @return [Hash<Integer, Array<TCGPlayerSDK::ProductPrice>>]
  def valid_prices
    if(@valid_prices.nil?)
      @valid_prices = {}
      @prices.each do |id, prl|
        @valid_prices[id] ||= []
        @valid_prices[id] = prl.select{|pr| pr.has_valid_prices?}
      end
    end

    return @valid_prices
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
class TCGPlayerSDK::ProductPrice < TCGPlayerSDK::ResponseStruct
  def initialize(hash = nil)
    super
  end

  ##
  # @return [Boolean] Returns false if there are no non-nil prices
  def has_valid_prices?
    return !(lowPrice.nil? && midPrice.nil? && highPrice.nil? && directLowPrice.nil? && marketPrice.nil?)
  end

  ##
  # Returns "price points" described by this price object.  i.e. "midPrice" and "highPrice".  These are also accessors,
  # so access away
  #   price.points.each{|pp| puts price.send(pp)}
  #
  # @return Array<Symbol>
  def points
    self.keys.select{|k| k.to_s =~ /Price/i}
  end
end
