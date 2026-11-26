module Admin
  class ContractsController < BaseController
    include ContractFiltering

    before_action :set_contract, only: %i[edit update destroy]
    before_action :load_choices, only: %i[new create edit update]

    def index
      @page = Page.new(filtered_contracts, number: params[:page])
    end

    def new
      @contract = Contract.new(signed_on: Date.current)
    end

    def create
      @contract = Contract.new(contract_params)

      if @contract.save
        redirect_to contract_path(@contract), notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @contract.update(contract_params)
        redirect_to contract_path(@contract), notice: t(".updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @contract.destroy!
      redirect_to admin_root_path, notice: t(".destroyed"), status: :see_other
    end

    private
      def set_contract
        @contract = Contract.find(params.expect(:id))
      end

      def load_choices
        @entities = Entity.order(:name).pluck(:name, :id)
        @contractors = Contractor.order(:name).pluck(:name, :id)
      end

      def contract_params
        params.expect(contract: %i[
          entity_id contractor_id reference object modality signed_on start_on end_on
          initial_value additions_value bidders_count
        ])
      end
  end
end
