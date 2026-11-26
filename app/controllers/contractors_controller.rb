class ContractorsController < ApplicationController
  allow_unauthenticated_access

  def show
    @contractor = Contractor.find(params.expect(:id))
    @summary = ProcurementSummary.new(@contractor.contracts)
    @page = Page.new(@contractor.contracts.includes(:entity).riskiest, number: params[:page])
  end
end
