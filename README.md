# TCG Player SDK

GitHub: https://github.com/cecomp64/tcg-player-sdk

Documentation: https://cecomp64.github.io/tcg-player-sdk/

# Installation

Via bundler:

```
gem 'tcg-player-sdk'
```

Via RubyGems:

```
gem install 'tcg-player-sdk'
```

# Instantiation and Authorization

TCGPlayerSDK can be instantiated with an optional user agent and required public and private keys.  Keys can come from environment variables, or be passed in to the constructor.
TCGPlayer.com typically asks users to use a consistent agent id so they can track your usage.

```ruby
require('tcg-player-sdk')

# Authorization is done automatically, and will use ENV['TCG_PLAYER_API_PUBLIC_KEY'] and
# ENV['TCG_PLAYER_API_PRIVATE_KEY'] if not otherwise specified
tcg = TCGPlayerSDK.new(user_agent: 'Your-User-Agent-Identifier')

# Otherwise, specify your public and private keys during initialization
tcg = TCGPlayerSDK.new(user_agent: 'Your-User-Agent-Identifier', public_key: 'foo', private_key: 'bar')

```

# Categories

List categories with the `#categories` function.  See [the docs](https://cecomp64.github.io/tcg-player-sdk/) for full details.

```ruby
categories = tcg.categories
ap categories

# Sample response
TCGPlayerSDK::ResponseStruct {
  :totalItems => 67,
    :success => true,
    :errors => [],
    :results => [
      [0] {
      "categoryId" => 64,
      "name" => "Alternate Souls",
      "modifiedOn" => "2020-10-14T20:08:31.777",
      "displayName" => "Alternate Souls",
      "seoCategoryName" => "Alternate Souls",
      "sealedLabel" => "Sealed Products",
      "nonSealedLabel" => "Cards",
      "conditionGuideUrl" => "https://store.tcgplayer.com/",
      "isScannable" => false,
      "popularity" => 0,
      "isDirect" => false
    },
      [1] {
      "categoryId" => 55,
      "name" => "Architect TCG",
      "modifiedOn" => "2021-10-11T21:26:34.46",
      "displayName" => "Architect TCG",
      "seoCategoryName" => "Architect TCG",
      "sealedLabel" => "Sealed Products",
      "nonSealedLabel" => "Singles",
      "conditionGuideUrl" => "https://store.tcgplayer.com/",
      "isScannable" => true,
      "popularity" => 0,
      "isDirect" => false
    },
      [2] {
      "categoryId" => 61,
      "name" => "Argent Saga TCG",
      "modifiedOn" => "2021-07-29T19:36:19.103",
      "displayName" => "Argent Saga TCG",
      "seoCategoryName" => "Argent Saga TCG",
      "sealedLabel" => "Sealed Products",
      "nonSealedLabel" => "Cards",
      "conditionGuideUrl" => "https://store.tcgplayer.com/",
      "isScannable" => true,
      "popularity" => 0,
      "isDirect" => false
    },
      # ...
    ],
    :base_query => {
      :url => "https://api.tcgplayer.com/catalog/categories",
      :params => {
      :noretry => true
    }
    },
    :http_response => nil, # Not actually, nil, just for completeness
      :tcg_object =>  nil, # ...
}

```

# ResponseStruct

Now is probably a good time to discuss the responses that the API returns.  In most cases, responses from the TCGPlayer
endpoints are returned as a wrapper around `OpenStruct` which we call `ResponseStruct`.  This allows for direct access
to the JSON response from the API.  It also gives us a good place to implement convenience functions and helpers.

Take the categories returned above, for example.  By default, requests that specify no limit return up to 10 items (most tcg-player-sdk 
functions allow for an optional paramters hash which can be used to specify your own limit or any other parameters for the endpoint.  See See [the docs](https://cecomp64.github.io/tcg-player-sdk/)).

But, let's say that you want to iterate over all the categories, and not have to guess how many there are in the first place,
just so you can make more queries and keep track of your offsets, and ... yuck.  Lucky for you, `ResponseStruct` implements
`Enumerable`, and will iterate over any reponse's `results` array, and automatically fetch additional results if the number of
available results is less than the total number of results.

You can iterate over all the results, and use any enumerable function, without worrying about setting the proper limits and re-querying like so:

```ruby
categories = tcg.categories

# Now do some Enumerable things, and they will operate on the full set of results
# 
# Let's see all the "Magic" categories
categories.select{|c| c =~ /Magic/}

# Or, print them all out why not
categories.each{|c| ap c}

# If you really did want just the results returned from your query, honoring your limit
# you can always access them directly
categories.results.size # => 10

# Just to reiterate, Enumerable methods will iterate over ALL results, even the onese not yet returned
categories.reduce(0){|sum, c| sum += 1} # => 67
```

The `ResponseStruct` always also contains a reference to the `tcg_object` that created this `ResponseStruct`, and a reference
to the original, unmodified `http_response` and `base_query`

Finally, everything else in the `ResponseStruct` can be accessed as any `OpenStruct`.  Oh, and did I mention it is recursive?
All hashes within a `ResponseStruct` will be treated as their own `ResponseStruct`. So, you can method-chain to your heart's content

```ruby
categories.results.first.name # => "Alternate Souls"
```

# Search Products

First step in doing anything interesting is usually getting one or more Product IDs.  A good way to do this is wth the 
search categories endpoint.  To do this, you'll want to inspect the search manifest to figure out what filters and sorting
options are available.  See [the docs](https://cecomp64.github.io/tcg-player-sdk/) for full details, but here's an example:

```ruby
manifest = tcg.category_search_manifest(3) # Good ol' "Category Three"

# Sorting and Filters accessors fast-forward you to the useful information
manifest.sorting
# => [#<TCGPlayerSDK::ResponseStruct text="A-Z", value="ProductName ASC">, #<TCGPlayerSDK::ResponseStruct text="Price: High to Low", value="MinPrice DESC">, #<TCGPlayerSDK::ResponseStruct text="Price: Low to High", value="MinPrice ASC">, #<TCGPlayerSDK::ResponseStruct text="Relevance", value="Relevance">, #<TCGPlayerSDK::ResponseStruct text="Best Selling", value="Sales DESC">]

manifest.filters.size # => 9
manifest.filters.first
#  => #<TCGPlayerSDK::ResponseStruct name="ProductName", displayName="Product Name", inputType="Text", items=[]> 

# Let's craft some search parameters now
search_params = {
  sort: 'ProductName ASC',
  limit: 10,
  offset: 0,
  filters: [ {
               name: 'ProductName',
               values: ['Alakazam']
             }]
}

search_results = tcg.category_search_products(3, search_params)

# Show the results, honoring the input limit
search_results.results # =>  [42444, 106996, 42346, 83496, 83501, 83499, 83497, 83500, 83498, 180715]

# Or, go do useful stuff on the full set of results
search_results.each do |pid|
  # Do something interesting on a per-product id basis
end
```

# Product Detail and Product Pricing

After all that hard work (hopefully made easier with this SDK), you've finally got yourself a nice, juicy list of Product IDs.


Now what?

Well, you probably want to know what the IDs actually represent (Product Details), and FINALLY what the pricing is for those products (that IS why we're here, isn't it!?).

```ruby
# Using the search results above, which return an array of product ids
all_ids = search_results.to_a
details = tcg.product_details(all_ids)

# These results are not subject to "LIMITS" Ha!
ap details.results.first
# =>
# TCGPlayerSDK::ResponseStruct {
# :productId => 42346,
#   :name => "Alakazam",
#   :cleanName => "Alakazam",
#   :imageUrl => "https://tcgplayer-cdn.tcgplayer.com/product/42346_200w.jpg",
#   :categoryId => 3,
#   :groupId => 604,
#   :url => "https://www.tcgplayer.com/product/42346/pokemon-base-set-alakazam",
#   :modifiedOn => "2021-10-07T12:55:24.89"
# }

# Of course that has all the details EXCEPT pricing, so... let's talk pricing
# pricing gets its own object :D
pricelist = tcg.product_pricing(all_ids)
pricelist.prices # These are prices grouped by productId
# => {42444=>[#<TCGPlayerSDK::ProductPrice productId=42444, lowPrice=nil, midPrice=nil, highPrice=nil, marketPrice=nil, directLowPrice=nil, subTypeName="Normal">, #<TCGPlayerSDK::ProductPrice productId=42444, lowPrice=10.0, midPrice=19.99, highPrice=159.99, marketPrice=21.88, directLowPrice=19.99, subTypeName="Holofoil">, ...}

# You may notice that you get many "empty" subtypes, so maybe you want just the "non-empty" or "valid" subtypes:
pricelist.valid_prices.values.flatten.size # => 39
pricelist.prices.flatten.size # => 196 (yuck)

# Finally, there's a ResponseStruct waiting for you
ap pricelist.valid_prices.values.first.first
# =>
# TCGPlayerSDK::ProductPrice {
# :productId => 42444,
#   :lowPrice => 10.0,
#   :midPrice => 19.99,
#   :highPrice => 159.99,
#   :marketPrice => 21.88,
#   :directLowPrice => 19.99,
#   :subTypeName => "Holofoil"
# }

# Ofcourse, pricelist is also a ResponseStruct, so take a look at the original response yourself
pricelist.success # => true (obviously)
```

Note that the return type of `#product_pricing` is a `ProductPriceList` (which is also a `ResponseStruct`).  This gives us
some helpers like `#prices` and `#valid_prices` which will group the otherwise flat results by `productId`.  The `#product_pricing` function
will automatically handle splitting up large requests (many productIds) into sever smaller ones, and seamlessly merge the results.

As always... See [the docs](https://cecomp64.github.io/tcg-player-sdk/) for full details.

# Testing

Yes, there are tests!  Run them via Rake:

```shell
rake test
```

Some tests will require you to set a valid public and private key.  Others do not.  Such is life.

We use `VCR` to record and replay http requests, so if you add new tests or update tests that end up making new or different
http requests, your tests will fail.  Please reset the cached responses with this command:

```shell
rake reset_fixtures
```

Then, re-running the tests will re-generate new traces.

```shell
rake test
```