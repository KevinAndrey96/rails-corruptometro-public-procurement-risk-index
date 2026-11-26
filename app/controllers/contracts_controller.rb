class ContractsController < ApplicationController
  include ContractFiltering

  allow_unauthenticated_access

  def index
    @departments = Entity.with_contracts.departments
    @page = Page.new(filtered_contracts, number: params[:page])
  end

  def show
    @contract = Contract.includes(:entity, :contractor).find(params.expect(:id))
  end
end
