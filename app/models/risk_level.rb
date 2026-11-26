module RiskLevel
  LEVELS = { low: 0..24, medium: 25..49, high: 50..100 }.freeze

  def self.for(score)
    LEVELS.find { |_level, range| range.cover?(score.to_i) }&.first || :low
  end
end
