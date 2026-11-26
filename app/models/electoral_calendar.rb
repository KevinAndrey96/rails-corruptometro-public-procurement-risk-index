# Ley 996 de 2005 (Ley de Garantías), artículo 33: direct contracting is suspended for every state entity
# from four months before the presidential election until the second round.
module ElectoralCalendar
  PRESIDENTIAL_ELECTIONS = [
    { first_round: Date.new(2014, 5, 25), second_round: Date.new(2014, 6, 15) },
    { first_round: Date.new(2018, 5, 27), second_round: Date.new(2018, 6, 17) },
    { first_round: Date.new(2022, 5, 29), second_round: Date.new(2022, 6, 19) },
    { first_round: Date.new(2026, 5, 31), second_round: Date.new(2026, 6, 21) }
  ].freeze

  RESTRICTION_MONTHS = 4

  def self.restricted_windows
    PRESIDENTIAL_ELECTIONS.map { |election| election[:first_round].months_ago(RESTRICTION_MONTHS)..election[:second_round] }
  end

  def self.restricted?(date)
    return false if date.blank?

    restricted_windows.any? { |window| window.cover?(date) }
  end
end
