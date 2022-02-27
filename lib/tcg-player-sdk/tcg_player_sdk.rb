##
# Wrap up request handling and common functions for TCGPlayer price API
class TCGPlayerSDK
  attr_accessor :bearer_token, :user_agent, :logger, :noretry, :public_key, :private_key

  API_VERSION = '1.39'
  BASE_URL = 'https://api.tcgplayer.com'
  TOKEN_URL = "#{BASE_URL}/token"
  CATALOG_URL = "#{BASE_URL}/catalog"
  CATEGORIES_URL = "#{CATALOG_URL}/categories"
  PRICING_URL = "#{BASE_URL}/pricing"

  ##
  # @param params[Hash]
  #   - user_agent: An identifying user agent string to be passed along with each request
  #   - bearer_token: Optionally pass in a previously authenticated bearer token
  #   - noretry: Set this to true to disable retrying queries when the bearer token is invalid
  #   - logger: Optionally pass a custom logging object
  #   - debug: Set output verbosity to DEBUG.  Default verbosity is WARN
  def initialize(params = {})
    self.user_agent = params[:user_agent] || 'Unknown'
    self.bearer_token = params[:bearer_token]
    self.noretry = params[:noretry]

    self.public_key = params[:public_key]
    self.private_key = params[:private_key]

    # Setup logging
    self.logger = params[:logger] || Logger.new(STDOUT)
    if(params[:debug])
      self.logger.level = Logger::DEBUG
    else
      self.logger.level = Logger::WARN
    end
  end

  # Get a new bearer token.  Specify your app's public and private key as parameters
  # or via Environment variables (or via .env) TCG_PLAYER_API_PUBLIC_KEY and TCG_PLAYER_API_PRIVATE_KEY
  #
  # @param params[Hash]
  #   - public_key: your TCP Player API pubic key
  #   - private_key: your TCP Player API pubic key
  #
  # @return [TCGPlayerSDK::BearerToken]
  def authorize(params = {})
    pub_key = params[:public_key] || public_key || ENV['TCG_PLAYER_API_PUBLIC_KEY']
    pri_key = params[:private_key] || private_key || ENV['TCG_PLAYER_API_PRIVATE_KEY']

    #"grant_type=client_credentials&client_id=PUBLIC_KEY&client_secret=PRIVATE_KEY"
    query_params = {grant_type: 'client_credentials', client_id: pub_key, client_secret: pri_key}
    response = HTTP.post(TOKEN_URL, form: query_params)
    resp_hash = response.parse
    logger.info resp_hash

    self.bearer_token = BearerToken.new resp_hash
  end

  ##
  # Perform a query on the TCGPlayer API
  #
  # @param url The API endpoint url, without arguments
  # @param _params[Hash]
  #   - post: When true, use a post request instead of a get request
  #   - noretry: Override any other retry settings and skip retry if true
  #   - *: Additional entries in _params hash are passed through to API as arguments
  #
  # @return [TCGPlayerSDK::ResponseStruct]
  def query(url, _params = {})
    params = _params.dup
    post = params.delete :post
    method = post ? 'post' : 'get'
    pkey = post ? :json : :params
    skip_retry = params.delete(:noretry) || noretry

    logger.debug "Query: #{url} params: "
    logger.ap params

    # Check for expiration of bearer token
    response = HTTP.auth("bearer #{bearer_token ? bearer_token.token : 'none'}").headers('User-Agent' => user_agent).send(method, url, pkey => params)
    ret = ResponseStruct.new response.parse.merge({base_query: {url: url, params: _params}, http_response: response, tcg_object: self})

    # Detect an invalid bearer token and attempt to retry
    if(!skip_retry && ret.errors && ret.errors.size > 0 && ret.errors.reduce(false){|sum, err| sum = (sum || (err =~ /bearer token/))})
      # Reauthorize and try again
      authorize
      ret = query(url, _params.merge({noretry: true}))
    end

    return ret
  end

  ##
  # Endpoint https://docs.tcgplayer.com/reference/catalog_getcategories-1
  #
  # @param params[Hash]
  #   - limit: max to return (default 10)
  #   - offset: number of categories to skip (for paging)
  #   - sort_order: property to sort by (defaults to name)
  #   - sort_desc: descending sort order
  #
  # @return [TCGPlayerSDK::ResponseStruct]
  def categories(params = {})
    query(CATEGORIES_URL, params)
  end

  ##
  # https://docs.tcgplayer.com/reference/catalog_getcategory-1
  #
  # @return [TCGPlayerSDK::ResponseStruct]
  def category_details(ids)
    query("#{CATEGORIES_URL}/#{ids.join(',')}")
  end

  # https://docs.tcgplayer.com/reference/catalog_getcategorysearchmanifest
  #
  # @return [TCGPlayerSDK::ResponseStruct]
  def category_search_manifest(id)
    Manifest.new(query("#{CATEGORIES_URL}/#{id}/search/manifest"))
  end

  # https://docs.tcgplayer.com/reference/catalog_searchcategory
  #
  # @param id[String] The category ID to search through
  # @param params[Hash] Put your additional search terms here:
  #   - sort: One of the available sort filters see manifest.results.first.sorting
  #   - limit: Cap the number of results to this limit
  #   - offset: Used with :limit to return a limited number of results in an arbitrary location.  i.e. for pagination
  #   - filters[Array<Hash>] An array of filters as described by manifest.results.first.filters.  Use the following format for Hash in the filters array
  #     - name[String]: Name of one of the filters from the manifest
  #     - values[Array<String>]: Specify which values to filter on
  #
  #   params = {
  #     sort: 'ProductName ASC',
  #     limit: 10,
  #     offset: 0,
  #     filters: [ {
  #       name: 'ProductName',
  #       values: ['Alakazam']
  #     }]
  #   }
  #
  #   results = tcg.category_search_products(3, params)
  #   results.results #=> [42444, 42346, 83496, 106996, 83501, 83499, 83497, 83500, 83498, 180715]
  #
  #   # Do something with each product ID... will automatically fetch new results
  #   all_ids = results.map{|r| r} #=> [42444, 42346, 83496, 106996, 83501, 83499, 83497, 83500, 83498, 180715, 83503, 83504, 117512, 117889, 117896, 117863, 83502, 226606, 228981, 228980, 228979, 251560, 84559, 84560, 118332, 117515, 117890, 88866]
  #
  # @return [TCGPlayerSDK::ResponseStruct]
  def category_search_products(id, params = {})
    search_params = {post: true}.merge(params)
    query("#{CATEGORIES_URL}/#{id}/search", search_params)
  end

  ##
  # https://docs.tcgplayer.com/reference/catalog_getproduct-1
  #
  def product_details(_ids, params = {})
    slice_ids(_ids) do |slice|
      query("#{CATALOG_URL}/products/#{id_list(slice)}", params)
    end
  end

  ##
  # Accessor to https://docs.tcgplayer.com/reference/pricing_getproductprices-1
  # Automatically handles arbitrarily large number of _ids and provides one merged response
  #
  # @param _ids An array of product IDs to query
  # @return [TCGPlayerSDK::ProductPriceList]
  def product_pricing(_ids)
    slice_ids(_ids) do |slice|
      TCGPlayerSDK::ProductPriceList.new(query("#{PRICING_URL}/product/#{id_list(slice)}"))
    end
  end

  private

  ##
  # Sanitize an array or string of ids to be compatible with the comma-separated values that the API expects
  #
  # @param value Accepts either an Array or String to convert to the API-friendly formatting
  # @return [String] ids separated by comma
  def id_list(value)
    value.is_a?(Array) ? value.join(',') : value
  end

  ##
  # Slice the input ids into smaller pieces, and execute the given block with each slice.  Merge the results
  def slice_ids(_ids, slice_size=200)
    ids = _ids.is_a?(Array) ? _ids : [_ids]
    resp = nil

    # Corner case for emptiness
    if(ids.empty?)
      resp = yield(ids)
    else
      ids.each_slice(slice_size) do |slice|
        response = yield(slice)
        if(resp.nil?)
          resp = response
        else
          resp.results += response.results if(response.results && resp.results)
        end
      end
    end

    return resp
  end

end