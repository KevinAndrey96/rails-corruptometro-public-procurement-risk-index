module Api
  module V1
    class EntitiesController < BaseController
      def index
        entities = Entity.with_contracts.ranked
        entities = entities.where(department: params[:department]) if params[:department].present?
        entities = entities.where(level: params[:level]) if Entity.levels.key?(params[:level])

        render_page build_page(entities), EntitySerializer
      end

      def show
        entity = Entity.find(params.expect(:id))

        render json: { data: EntitySerializer.new(entity).as_json }
      end
    end
  end
end
