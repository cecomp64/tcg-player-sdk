class TCGPlayerAPI::ResponseStruct < OpenStruct
  include Enumerable

  ##
  # Attempt to execute a given block of code.  Return the result on success,
  # or the *default* on failure.
  #
  #   try(nil) {self.results.first.name}
  def try(default, &blk)
    begin
      return self.instance_eval(&blk)
    rescue
      return default
    end
  end

  ##
  # Iterates over `self.results` and attempts to fetch any missing results.
  # For example, if you get a response that has "totalItems" equal to a number that is larger
  # than the size of "results", then this function easily lets you iterate over every item,
  # and will automatically fetch any items not included in "results."
  #
  # Since this class includes Enumberable, any Enumerable methods are also available.
  #
  # Example:
  #   2.7.2 :057 > cl = tcg.categories
  #    D, [2022-01-25T22:20:34.597036 #67042] DEBUG -- : Query: https://api.tcgplayer.com/catalog/categories params:
  #    D, [2022-01-25T22:20:34.597129 #67042] DEBUG -- : {}
  #    TCGPlayerAPI::ResponseStruct {
  #        :totalItems => 67,
  #        :results => [...]
  #
  #    2.7.2 :072 > cl.results.size
  #    10
  #
  #    2.7.2 :073 > allcl = cl.map{|result| result.name}
  #    D, [2022-01-25T22:29:11.506994 #67042] DEBUG -- : Query: https://api.tcgplayer.com/catalog/categories params:
  #    D, [2022-01-25T22:29:11.507161 #67042] DEBUG -- : {
  #       :offset => 10,
  #       :limit => 100
  #     }
  #     [
  #     [ 0] "Alternate Souls",
  #     [ 1] "Architect TCG",
  #     [ 2] "Argent Saga TCG",
  #     [ 3] "Axis & Allies",
  #     ...
  #     [64] "WoW",
  #     [65] "YuGiOh",
  #     [66] "Zombie World Order TCG"
  #     ]
  def each(&block)
    if(!self.totalItems.nil? && !self.results.nil? && !self.tcg_object.nil?)
      max_items = self.totalItems

      # Defaults
      offset = self.results.size
      limit = defined?(self.base_query.params.limit) ? self.base_query.params.limit : 100
      offset += defined?(self.base_query.params.offset) ? self.base_query.params.offset : 0

      self.results.each(&block)
      while(offset < max_items && !self.results.empty?)
        # Fetch more results
        fetch_params = self.base_query.params.dup.to_h
        fetch_params[:offset] = offset
        fetch_params[:limit] = limit
        more_results = self.tcg_object.query(self.base_query.url, fetch_params)

        # iterate
        more_results.results.each(&block)
        offset += more_results.results.size
      end
    else
      # Throw an exception?
    end
  end

  # Create ResponseStructs out of any nested hashes or arrays of hashes
  def method_missing(mid, *args)
    # Avoid assignments
    if(mid.to_s =~ /=/)
      return super
    else
      # Get original value
      value = super

      # Turn it into a ResponseStruct
      new_val = (value.is_a?(Array) && value.first.is_a?(Hash)) ?
                  value.map{|v| TCGPlayerAPI::ResponseStruct.new(v)} :
                  ((value.is_a?(Hash)) ? TCGPlayerAPI::ResponseStruct.new(value) : value)

      # Save it back as a ResponseStruct
      send("#{mid.to_s}=", new_val)
      return new_val
    end
  end

  def respond_to_missing?(mid, include_private = nil)
    super
  end

  def to_s
    ap self, indent: -2
  end

  def to_h(*args)
    self.marshal_dump
  end

  def keys
    return self.to_h.keys
  end
end