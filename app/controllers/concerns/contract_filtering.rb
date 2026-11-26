# Shared contract filters for the public listing and the JSON API.
module ContractFiltering
  extend ActiveSupport::Concern

  private
    def filtered_contracts
      contracts = Contract.includes(:entity, :contractor).search(params[:q])
      contracts = contracts.flagged_with(params[:flag]) if RedFlag.key?(params[:flag])
      contracts = contracts.where(modality: params[:modality]) if Contract.modalities.key?(params[:modality])
      contracts = contracts.joins(:entity).where(entities: { department: params[:department] }) if params[:department].present?
      contracts = contracts.where(risk_score: params[:min_score].to_i..) if params[:min_score].present?

      params[:sort] == "recent" ? contracts.recent : contracts.riskiest
    end
end
