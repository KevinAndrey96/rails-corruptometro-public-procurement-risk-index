module Api
  module V1
    class RedFlagsController < BaseController
      def index
        render json: {
          data: RedFlag.all.map do |flag|
            { key: flag.key, name: flag.name, weight: flag.weight, description: flag.description, legal_basis: flag.legal_basis }
          end
        }
      end
    end
  end
end
