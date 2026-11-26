# Recomputes the red flags of every contract of an entity and the entity risk index,
# weighted by contract value so large contracts weigh more than small ones.
class RiskAssessor
  def initialize(entity)
    @entity = entity
  end

  def call
    contracts = @entity.contracts.includes(:contractor).to_a
    total = contracts.sum(&:total_value)
    shares = contractor_shares(contracts, total)

    Entity.transaction do
      contracts.each do |contract|
        flags = flags_for(contract, shares.fetch(contract.contractor_id, 0.0), contracts.size)
        contract.update_columns(red_flags: flags.map(&:to_s), risk_score: RedFlag.score(flags))
      end

      @entity.update_columns(risk_index: weighted_index(contracts, total), contracted_value: total)
    end
  end

  def flags_for(contract, contractor_share, contracts_count)
    flags = []
    flags << :additions_over_cap if contract.additions_ratio > RedFlag::ADDITIONS_CAP
    flags << :single_bidder if contract.competitive? && contract.bidders_count == 1
    flags << :direct_award if contract.contratacion_directa?
    flags << :new_contractor if new_contractor?(contract)
    flags << :contractor_concentration if concentrated?(contractor_share, contracts_count)
    flags << :electoral_restriction if contract.contratacion_directa? && ElectoralCalendar.restricted?(contract.signed_on)
    flags
  end

  private
    def contractor_shares(contracts, total)
      return {} if total.zero?

      contracts.group_by(&:contractor_id).transform_values { |owned| owned.sum(&:total_value).fdiv(total) }
    end

    def new_contractor?(contract)
      incorporated_on = contract.contractor.incorporated_on
      return false if incorporated_on.blank?

      (contract.signed_on - incorporated_on).to_i < RedFlag::NEW_CONTRACTOR_DAYS
    end

    def concentrated?(share, contracts_count)
      contracts_count >= RedFlag::CONCENTRATION_MINIMUM_CONTRACTS && share > RedFlag::CONCENTRATION_SHARE
    end

    def weighted_index(contracts, total)
      return 0 if total.zero?

      contracts.sum { |contract| contract.risk_score * contract.total_value }.fdiv(total).round
    end
end
