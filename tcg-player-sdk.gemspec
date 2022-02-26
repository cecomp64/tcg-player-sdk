Gem::Specification.new do |s|
  s.name        = 'tcg-player-sdk'
  s.version     = '0.1.5'
  s.summary     = "A Ruby interface to the TCGPlayer.com API for trading card prices."
  s.description = "The tcg-player-sdk gem is a convenient wrapper to the TCGPlayer JSON API.  Easily query the entire API, with helpers and accessors for common queries.  This gem also provides helpers for Pokemon-specific queries.  A work in progress."
  s.authors     = ["Carl Svensson"]
  s.email       = 'csvenss2@gmail.com'
  s.files       = ['lib/tcg-player-sdk.rb'] + Dir.glob('lib/tcg-player-sdk/*')
  s.homepage    = 'https://cecomp64.github.io/tcg-player-sdk/'
  s.license       = 'MIT'
  s.require_paths = ["lib"]

  s.add_dependency "http", "~> 5.0.4"
  s.add_dependency "dotenv", "~> 2.7.6"
  s.add_dependency "amazing_print", "~> 1.4.0"
end