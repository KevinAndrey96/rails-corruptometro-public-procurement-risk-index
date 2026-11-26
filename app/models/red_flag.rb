# Catalog of public procurement red flags. Weights add up to 100, so a contract risk score is the sum of its flags.
class RedFlag
  Definition = Data.define(:key, :weight) do
    def name
      I18n.t("red_flags.#{key}.name")
    end

    def description
      I18n.t("red_flags.#{key}.description")
    end

    def legal_basis
      I18n.t("red_flags.#{key}.legal_basis")
    end

    def to_param
      key.to_s
    end
  end

  ALL = [
    Definition.new(key: :additions_over_cap, weight: 30),
    Definition.new(key: :single_bidder, weight: 20),
    Definition.new(key: :direct_award, weight: 15),
    Definition.new(key: :new_contractor, weight: 15),
    Definition.new(key: :contractor_concentration, weight: 10),
    Definition.new(key: :electoral_restriction, weight: 10)
  ].index_by(&:key).freeze

  ADDITIONS_CAP = 0.5
  NEW_CONTRACTOR_DAYS = 365
  CONCENTRATION_SHARE = 0.4
  CONCENTRATION_MINIMUM_CONTRACTS = 5

  def self.all
    ALL.values
  end

  def self.find(key)
    ALL.fetch(key.to_s.to_sym)
  end

  def self.key?(key)
    ALL.key?(key.to_s.to_sym)
  end

  def self.where(keys)
    Array(keys).filter_map { |key| ALL[key.to_s.to_sym] }
  end

  def self.score(keys)
    [ where(keys).sum(&:weight), 100 ].min
  end
end
