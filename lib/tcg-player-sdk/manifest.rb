# Add some shortcuts and helpers to parse the manifest
class TCGPlayerSDK::Manifest < TCGPlayerSDK::ResponseStruct

  def initialize(hash = nil)
    super
  end

  ##
  # Pick out the sorting struct from the response
  #
  # @return [Array<TCGPlayerSDK::ResponseStruct>]
  def sorting
    if(self.results && self.results.is_a?(Array))
      @sorting ||= self.results.first.sorting
    end

    return @sorting
  end

  ##
  # @return [Array<String>] The actual values that are legitimate inputs to search query's sort field
  def sort_values
    _sorting = sorting || []
    @sort_values ||= _sorting.map(&:value)
  end

  ##
  # Pick out the filters struct from the response
  #
  # @return [Array<TCGPlayerSDK::ResponseStruct>]
  def filters
    if(self.results && self.results.is_a?(Array))
      @filters ||= self.results.first.filters
    end

    return @filters
  end
end