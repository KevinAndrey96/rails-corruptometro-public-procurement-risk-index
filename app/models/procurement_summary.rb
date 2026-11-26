# Headline figures for a set of contracts: volume, value, direct awards and how often each red flag shows up.
class ProcurementSummary
  def initialize(contracts = Contract.all)
    @contracts = contracts
  end

  def contracts_count
    @contracts_count ||= @contracts.count
  end

  def total_value
    @total_value ||= @contracts.sum("initial_value + additions_value")
  end

  def flagged_count
    @flagged_count ||= @contracts.where(risk_score: 1..).count
  end

  def flagged_share
    share(flagged_count, contracts_count)
  end

  def direct_award_share
    share(@contracts.contratacion_directa.sum("initial_value + additions_value"), total_value)
  end

  def flag_counts
    @flag_counts ||= RedFlag.all.index_with { |flag| @contracts.flagged_with(flag.key).count }
  end

  private
    def share(part, whole)
      whole.to_i.zero? ? 0.0 : part.fdiv(whole)
    end
end
