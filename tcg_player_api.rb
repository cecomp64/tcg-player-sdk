require 'http'
require 'logger'
require 'awesome_print'

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
    # Iterates over `self.results` and attempts to fetch any missing results
    def each(&block)
      if(!self.totalItems.nil? && !self.results.nil?)
        max_items = self.totalItems
        fetched_items = self.results.size

        # Defaults
        offset = self.results.size
        limit = defined?(self.base_query.params.limit) ? self.base_query.params.limit : 100
        offset += defined?(self.base_query.params.offset) ? self.base_query.params.offset : 0

        self.results.each(&block)
        while(fetched_items != max_items && !self.results.empty?)
          # Fetch more results
          # Need query... put this in a query object?
          # iterate
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
  end

  class ResultArray < Array
  end

  # Helpers for pokemon-centric tasks
  class Pokemon
    attr_accessor :tcg

    def initialize(_tcg)
      self.tcg = _tcg
      @category = nil
    end

    def category
      return @category unless(@category.nil?)
      limit = 100
      categories = tcg.categories(limit: limit)
      pc = categories.results.select{|c| c.name =~ /Pokemon/i}.first
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
  end

  # Get a new bearer token
  # Do this automatically if other requests fail
  def authorize(public_key, private_key)
    #"grant_type=client_credentials&client_id=PUBLIC_KEY&client_secret=PRIVATE_KEY"
    params = {grant_type: 'client_credentials', client_id: public_key, client_secret: private_key}
    response = HTTP.post(TOKEN_URL, form: params)
    resp_hash = response.parse
    logger.info resp_hash

    self.bearer_token = BearerToken.new resp_hash
  end

  # Error handling?
  def query(url, _params = {})
    params = _params.dup
    post = params.delete :post
    method = post ? 'post' : 'get'
    pkey = post ? :form : :params
    response = HTTP.auth("bearer #{bearer_token.token}").send(method, url, pkey => params)
    ResponseStruct.new response.parse.merge({base_query: {url: url, params: _params}, http_response: response})
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
  def category_search_products(params = {})
    search_params = {post: true}.merge(params)
    query("#{CATEGORIES_URL}/#{id}/search", search_params)
  end
end
