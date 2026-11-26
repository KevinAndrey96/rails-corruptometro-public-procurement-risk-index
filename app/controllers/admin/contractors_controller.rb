module Admin
  class ContractorsController < BaseController
    before_action :set_contractor, only: %i[edit update]

    def index
      @page = Page.new(Contractor.order(:name), number: params[:page])
    end

    def new
      @contractor = Contractor.new(document_type: :nit)
    end

    def create
      @contractor = Contractor.new(contractor_params)

      if @contractor.save
        redirect_to admin_contractors_path, notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @contractor.update(contractor_params)
        redirect_to admin_contractors_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      def set_contractor
        @contractor = Contractor.find(params.expect(:id))
      end

      def contractor_params
        params.expect(contractor: %i[name document_type document_number incorporated_on])
      end
  end
end
