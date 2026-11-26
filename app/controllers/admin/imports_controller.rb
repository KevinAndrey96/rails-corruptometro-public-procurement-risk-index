module Admin
  class ImportsController < BaseController
    def new
      @import = ContractImport.new(content: "")
    end

    def create
      file = params[:file]

      if file.respond_to?(:size) && file.size > ContractImport::MAX_BYTES
        @import = ContractImport.new(content: "")
        @import.errors.add(:base, :file_too_large, megabytes: ContractImport::MAX_BYTES / 1.megabyte)
        return render :new, status: :unprocessable_content
      end

      @import = ContractImport.new(content: file.respond_to?(:read) ? file.read : "")

      if @import.valid?
        @result = @import.call
        render :show
      else
        render :new, status: :unprocessable_content
      end
    end
  end
end
