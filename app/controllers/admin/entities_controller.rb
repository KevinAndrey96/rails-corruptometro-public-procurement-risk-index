module Admin
  class EntitiesController < BaseController
    before_action :set_entity, only: %i[edit update]

    def index
      @page = Page.new(Entity.order(:name), number: params[:page])
    end

    def new
      @entity = Entity.new
    end

    def create
      @entity = Entity.new(entity_params)

      if @entity.save
        redirect_to admin_entities_path, notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @entity.update(entity_params)
        redirect_to admin_entities_path, notice: t(".updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
      def set_entity
        @entity = Entity.find(params.expect(:id))
      end

      def entity_params
        params.expect(entity: %i[name nit level department])
      end
  end
end
