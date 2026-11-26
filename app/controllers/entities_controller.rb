class EntitiesController < ApplicationController
  allow_unauthenticated_access

  def index
    entities = Entity.with_contracts.ranked
    entities = entities.where(department: params[:department]) if params[:department].present?
    entities = entities.where(level: params[:level]) if Entity.levels.key?(params[:level])

    @departments = Entity.with_contracts.departments
    @page = Page.new(entities, number: params[:page])
  end

  def show
    @entity = Entity.find(params.expect(:id))
    @summary = ProcurementSummary.new(@entity.contracts)
    @top_contractors = top_contractors
    @page = Page.new(@entity.contracts.includes(:contractor).riskiest, number: params[:page])
  end

  private
    def top_contractors
      @entity.contracts
        .joins(:contractor)
        .group("contractors.id", "contractors.name")
        .order(Arel.sql("SUM(contracts.initial_value + contracts.additions_value) DESC"))
        .limit(5)
        .pluck("contractors.id", "contractors.name", Arel.sql("SUM(contracts.initial_value + contracts.additions_value)"))
    end
end
