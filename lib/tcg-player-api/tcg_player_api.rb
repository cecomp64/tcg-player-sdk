##
# Wrap up request handling and common functions for TCGPlayer price API
class TCGPlayerAPI
  attr_accessor :bearer_token, :user_agent, :logger

  API_VERSION = '1.39'
  BASE_URL = 'https://api.tcgplayer.com'
  TOKEN_URL = "#{BASE_URL}/token"
  CATALOG_URL = "#{BASE_URL}/catalog"
  CATEGORIES_URL = "#{CATALOG_URL}/categories"
  PRICING_URL = "#{BASE_URL}/pricing"

  def initialize(params = {})
    self.user_agent = params[:user_agent] || 'Unknown'
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

    response = HTTP.auth("bearer #{bearer_token.token}").headers('User-Agent' => user_agent).send(method, url, pkey => params)
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

  ##
  # Accessor to https://docs.tcgplayer.com/reference/pricing_getproductprices-1
  #
  # @param ids An array of product IDs to query
  # @return ResponseStruct with raw query results
  def product_pricing(_ids)
    ids = _ids.is_a?(Array) ? _ids.join(',') : _ids
    query("#{PRICING_URL}/product/#{ids}")
  end
end