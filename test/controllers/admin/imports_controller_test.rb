require "test_helper"

module Admin
  class ImportsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as(users(:one)) }

    test "shows the upload form with the expected columns" do
      get new_admin_import_path

      assert_response :success
      assert_select "input[type=file][name=file]"
      assert_select "code", /referencia_del_contrato/
    end

    test "imports an uploaded csv and reports the result" do
      assert_difference "Contract.count", 2 do
        post admin_import_path, params: { file: fixture_file_upload("contratos.csv", "text/csv") }
      end

      assert_response :success
      assert_select ".kpi-value", "2"
    end

    test "rejects uploads without the required columns" do
      file = Rack::Test::UploadedFile.new(StringIO.new(+"a,b\n1,2"), "text/csv", original_filename: "malo.csv")

      assert_no_difference "Contract.count" do
        post admin_import_path, params: { file: file }
      end

      assert_response :unprocessable_content
      assert_select ".form-errors", /Faltan columnas obligatorias/
    end

    test "rejects a missing file" do
      post admin_import_path

      assert_response :unprocessable_content
      assert_select ".form-errors", /Selecciona un archivo CSV/
    end
  end
end
