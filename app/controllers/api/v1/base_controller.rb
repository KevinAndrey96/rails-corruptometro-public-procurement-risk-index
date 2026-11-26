module Api
  module V1
    # Read-only public API. Responses are JSON and rate limited per client IP.
    class BaseController < ActionController::API
      rate_limit to: 120, within: 1.minute,
        with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "not_found" }, status: :not_found
      end

      private
        def render_page(page, serializer)
          render json: {
            data: page.records.map { |record| serializer.new(record).as_json },
            meta: { page: page.number, per_page: page.size, total_count: page.total_count, total_pages: page.total_pages }
          }
        end

        def build_page(scope)
          Page.new(scope, number: params[:page], size: params.fetch(:per_page, Page::DEFAULT_SIZE))
        end
    end
  end
end
