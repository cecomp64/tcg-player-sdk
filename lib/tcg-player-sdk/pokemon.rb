# Helpers for pokemon-centric tasks
class TCGPlayerSDK::Pokemon
  attr_accessor :tcg

  def initialize(_tcg)
    self.tcg = _tcg
    @category = nil
  end

  def category
    @category ||= tcg.categories(limit: 100).select{|c| c.name =~ /Pokemon/i}.first
  end

  def categoryId
    category.categoryId
  end

  def manifest
    @manifest ||= tcg.category_search_manifest(categoryId)
  end

  ##
  # Returns the TCGPlaeryAPI filter corresponding to Sets
  def sets
    @set_filter ||= @manifest.results.first.filters.select{|f| f.name == 'SetName'}.first
  end

  ##
  # @return [Array<TCGPlayerSDK::ResponseStruct>] Response struct with keys :value and :text, which correspond to
  # the available ways to sort search data.  Set :sort in your search parameters to one of the returned :value
  def sorting
    @sorting ||= @manifest.results.first.sorting
  end

  ##
  # Returns the TCGPlayerSDK filter item corresponding to the input set
  #
  #   pokemon.set('Base Set')
  #   [
  #       [0] TCGPlayerSDK::ResponseStruct {
  #            :text => "Base Set",
  #           :value => "Base Set"
  #       }
  #   ]
  def set(set_name)
    sets.items.select{|i| i.text == set_name}
  end
end
