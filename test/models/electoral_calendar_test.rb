require "test_helper"

class ElectoralCalendarTest < ActiveSupport::TestCase
  test "restricts from four months before the first round until the second round" do
    assert ElectoralCalendar.restricted?(Date.new(2022, 1, 29))
    assert ElectoralCalendar.restricted?(Date.new(2022, 6, 19))
    assert ElectoralCalendar.restricted?(Date.new(2026, 3, 2))
  end

  test "does not restrict outside the windows" do
    assert_not ElectoralCalendar.restricted?(Date.new(2022, 1, 28))
    assert_not ElectoralCalendar.restricted?(Date.new(2022, 6, 20))
    assert_not ElectoralCalendar.restricted?(Date.new(2024, 3, 1))
    assert_not ElectoralCalendar.restricted?(nil)
  end
end
