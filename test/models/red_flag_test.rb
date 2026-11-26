require "test_helper"

class RedFlagTest < ActiveSupport::TestCase
  test "weights add up to one hundred" do
    assert_equal 100, RedFlag.all.sum(&:weight)
  end

  test "score sums the weights of known flags and ignores unknown keys" do
    assert_equal 50, RedFlag.score(%w[additions_over_cap single_bidder])
    assert_equal 15, RedFlag.score([ :direct_award, "unknown" ])
    assert_equal 0, RedFlag.score([])
  end

  test "every flag has a name, description and legal basis in spanish" do
    RedFlag.all.each do |flag|
      assert_no_match(/translation missing/i, flag.name)
      assert_no_match(/translation missing/i, flag.description)
      assert_no_match(/translation missing/i, flag.legal_basis)
    end
  end

  test "find raises on unknown keys" do
    assert_equal 30, RedFlag.find("additions_over_cap").weight
    assert_raises(KeyError) { RedFlag.find("bribery") }
  end
end
