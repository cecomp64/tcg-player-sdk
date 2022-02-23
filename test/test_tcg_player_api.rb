require 'test_helper'

class TCGPlayerAPITest < Minitest::Test
  attr_accessor :tcg

  def test_authorize
    tcg = TCGPlayerAPI.new
    tcg.authorize
  end
end
