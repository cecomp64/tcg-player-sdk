require 'http'
require 'logger'
require 'amazing_print'
require 'dotenv/load'

##
# Wrap up request handling and common functions for TCGPlayer price API
class TCGPlayerAPI
  class BearerToken
    attr_accessor :expires_in, :token, :expiration, :issued

    def initialize(params = {})
      self.expires_in = params['expires_in']
      self.token = params['access_token']
      self.issued = DateTime.parse(params['.issued'])
      self.expiration = DateTime.parse(params['.expires'])
    end

    def expired?

    end

    def to_s
      ap self, indent: -2
    end
  end

  class ResponseStruct < OpenStruct
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
                 value.map{|v| ResponseStruct.new(v)} :
                 ((value.is_a?(Hash)) ? ResponseStruct.new(value) : value)

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

  # Helpers for pokemon-centric tasks
  class Pokemon
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
    # Returns the TCGPlayerAPI filter item corresponding to the input set
    #
    #   pokemon.set('Base Set')
    #   [
    #       [0] TCGPlayerAPI::ResponseStruct {
    #            :text => "Base Set",
    #           :value => "Base Set"
    #       }
    #   ]
    def set(set_name)
      sets.items.select{|i| i.text == set_name}
    end
  end

  attr_accessor :bearer_token, :user_agent, :logger

  API_VERSION = '1.39'
  BASE_URL = 'https://api.tcgplayer.com'
  TOKEN_URL = "#{BASE_URL}/token"
  CATALOG_URL = "#{BASE_URL}/catalog"
  CATEGORIES_URL = "#{CATALOG_URL}/categories"

  def initialize(params = {})
    self.user_agent = params[:user_agent]
    self.logger = params[:logger] || Logger.new(STDOUT)
    self.logger.level = Logger::DEBUG if(params[:debug])
  end

  # Get a new bearer token.  Specify your app's public and private key as parameters
  # or via Environment variables (or via .env) TCG_PLAYER_API_PUBLIC_KEY and TCG_PLAYER_API_PRIVATE_KEY
  # Parameters:
  #   public_key: your TCP Player API pubic key
  #   private_key: your TCP Player API pubic key
  def authorize(params = {})
    public_key = params[:public_key] || ENV['TCG_PLAYER_API_PUBLIC_KEY']
    private_key = params[:private_key] || ENV['TCG_PLAYER_API_PRIVATE_KEY']

    #"grant_type=client_credentials&client_id=PUBLIC_KEY&client_secret=PRIVATE_KEY"
    query_params = {grant_type: 'client_credentials', client_id: public_key, client_secret: private_key}
    response = HTTP.post(TOKEN_URL, form: query_params)
    resp_hash = response.parse
    logger.info resp_hash

    self.bearer_token = BearerToken.new resp_hash
  end

  # Error handling?
  def query(url, _params = {})
    params = _params.dup
    post = params.delete :post
    method = post ? 'post' : 'get'
    pkey = post ? :json : :params

    logger.debug "Query: #{url} params: "
    logger.ap params

    response = HTTP.auth("bearer #{bearer_token.token}").send(method, url, pkey => params)
    ResponseStruct.new response.parse.merge({base_query: {url: url, params: _params}, http_response: response, tcg_object: self})
  end

  # limit - max to return (default 10)
  # offset - number of categories to skip (for paging)
  # sort_order - property to sort by (defaults to name)
  # sort_desc - descending sort order
  # https://docs.tcgplayer.com/reference/catalog_getcategories-1
  def categories(params = {})
    query(CATEGORIES_URL, params)
  end

  # https://docs.tcgplayer.com/reference/catalog_getcategory-1
  def category_details(ids)
    query("#{CATEGORIES_URL}/#{ids.join(',')}")
  end

  # https://docs.tcgplayer.com/reference/catalog_getcategorysearchmanifest
  def category_search_manifest(id)
    query("#{CATEGORIES_URL}/#{id}/search/manifest")
  end

  # https://docs.tcgplayer.com/reference/catalog_searchcategory
  def category_search_products(id, params = {})
    search_params = {post: true}.merge(params)
    query("#{CATEGORIES_URL}/#{id}/search", search_params)
  end

  #def product_details(pids, params = {})
  #  query("#{CATEGORIES_URL}/#{id}/search", search_params)
  #end
end
