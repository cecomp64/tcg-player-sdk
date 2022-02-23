##
# Wrap up request handling and common functions for TCGPlayer price API
class TCGPlayerAPI
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
  # @return [TCGPlayerAPI::BearerToken]
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
  # @return [TCGPlayerAPI::ResponseStruct]
  def query(url, _params = {})
    params = _params.dup
    post = params.delete :post
    method = post ? 'post' : 'get'
    pkey = post ? :json : :params
    skip_retry = params.delete(:noretry) || noretry

    logger.debug "Query: #{url} params: "
    logger.ap params

    # Check for expiration of bearer token
    response = HTTP.auth("bearer #{bearer_token.token}").headers('User-Agent' => user_agent).send(method, url, pkey => params)
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
  # @return [TCGPlayerAPI::ResponseStruct]
  def categories(params = {})
    query(CATEGORIES_URL, params)
  end

  ##
  # https://docs.tcgplayer.com/reference/catalog_getcategory-1
  #
  # @return [TCGPlayerAPI::ResponseStruct]
  def category_details(ids)
    query("#{CATEGORIES_URL}/#{ids.join(',')}")
  end

  # https://docs.tcgplayer.com/reference/catalog_getcategorysearchmanifest
  #
  # @return [TCGPlayerAPI::ResponseStruct]
  def category_search_manifest(id)
    query("#{CATEGORIES_URL}/#{id}/search/manifest")
  end

  # https://docs.tcgplayer.com/reference/catalog_searchcategory
  #
  # @return [TCGPlayerAPI::ResponseStruct]
  def category_search_products(id, params = {})
    search_params = {post: true}.merge(params)
    query("#{CATEGORIES_URL}/#{id}/search", search_params)
  end

  #def product_details(pids, params = {})
  #  query("#{CATEGORIES_URL}/#{id}/search", search_params)
  #end

  ##
  # Accessor to https://docs.tcgplayer.com/reference/pricing_getproductprices-1
  #
  # @param ids An array of product IDs to query
  # @return [TCGPlayerAPI::ResponseStruct]
  def product_pricing(_ids)
    ids = _ids.is_a?(Array) ? _ids.join(',') : _ids
    query("#{PRICING_URL}/product/#{ids}")
  end
end