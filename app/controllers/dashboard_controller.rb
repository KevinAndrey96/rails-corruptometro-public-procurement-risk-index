class DashboardController < ApplicationController
  allow_unauthenticated_access

  def show
    @summary = ProcurementSummary.new
    @riskiest_entities = Entity.with_contracts.ranked.limit(5)
    @riskiest_contracts = Contract.includes(:entity, :contractor).riskiest.limit(5)
  end
end
