require "test_helper"

class NitValidatorTest < ActiveSupport::TestCase
  test "computes the DIAN check digit" do
    assert_equal 9, NitValidator.check_digit("899999061")
    assert_equal 1, NitValidator.check_digit("900456123")
    assert_equal 7, NitValidator.check_digit("800111222")
  end

  test "accepts well formed NITs with the right check digit" do
    assert NitValidator.valid?("899999061-9")
    assert NitValidator.valid?("901845632-1")
  end

  test "rejects wrong check digits and malformed values" do
    assert_not NitValidator.valid?("899999061-8")
    assert_not NitValidator.valid?("899999061")
    assert_not NitValidator.valid?("89999906-19")
    assert_not NitValidator.valid?("")
    assert_not NitValidator.valid?(nil)
  end
end
