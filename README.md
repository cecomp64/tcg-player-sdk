# TCG Player API

```ruby
2.7.1 :002 > tcg = TCGPlayerAPI.new
2.7.1 :003 > tcg.authorize

2.7.1 :011 > pika = TCGPlayerAPI::Pokemon.new tcg
2.7.1 :014 > pika.category

D, [2022-02-15T15:15:51.969843 #10721] DEBUG -- : Query: https://api.tcgplayer.com/catalog/categories params: 
D, [2022-02-15T15:15:51.969977 #10721] DEBUG -- : {
:limit => 100
}
TCGPlayerAPI::ResponseStruct {
  :categoryId => 3,
    :name => "Pokemon",
    :modifiedOn => "2022-02-15T21:55:12.807",
    :displayName => "Pokemon",
    :seoCategoryName => "Pokemon",
    :sealedLabel => "Sealed Products",
    :nonSealedLabel => "Single Cards",
    :conditionGuideUrl => "https://store.tcgplayer.com/help/cardconditionguide",
    :isScannable => true,
    :popularity => 576635,
    :isDirect => true
}

2.7.1 :039 > mani = pika.manifest
2.7.1 :038 > mani.to_h.keys
[
  [0] :success,
  [1] :errors,
  [2] :results,
  [3] :base_query,
  [4] :http_response,
  [5] :tcg_object
]

2.7.1 :045 > mani.results.first.keys
[
  [0] :sorting,
  [1] :filters,
  [2] :keys
]
2.7.1 :046 > mani.results.first.sorting
[
  [0] TCGPlayerAPI::ResponseStruct {
  :text => "A-Z",
    :value => "ProductName ASC"
},
  [1] TCGPlayerAPI::ResponseStruct {
  :text => "Price: High to Low",
    :value => "MinPrice DESC"
},
  [2] TCGPlayerAPI::ResponseStruct {
  :text => "Price: Low to High",
    :value => "MinPrice ASC"
},
  [3] TCGPlayerAPI::ResponseStruct {
  :text => "Relevance",
    :value => "Relevance"
},
  [4] TCGPlayerAPI::ResponseStruct {
  :text => "Best Selling",
    :value => "Sales DESC"
}
]

2.7.1 :052 > mani.results.first.filters.map(&:name)
[
  [0] "ProductName",
  [1] "CardText",
  [2] "SetName",
  [3] "Rarity",
  [4] "HP",
  [5] "EnergyType",
  [6] "CardType",
  [7] "RetreatCost",
  [8] "Price"
]

sets = mani.results.first.filters.select{|f| f.name == 'SetName'}


```

