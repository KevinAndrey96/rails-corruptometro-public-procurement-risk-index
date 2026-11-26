module Api
  module V1
    class ContractsController < BaseController
      include ContractFiltering

      def index
        render_page build_page(filtered_contracts), ContractSerializer
      end

      def show
        contract = Contract.includes(:entity, :contractor).find(params.expect(:id))

        render json: { data: ContractSerializer.new(contract).as_json }
      end
    end
  end
end
