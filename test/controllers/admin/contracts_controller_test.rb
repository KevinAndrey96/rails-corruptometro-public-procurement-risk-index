require "test_helper"

module Admin
  class ContractsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as(users(:one)) }

    test "requires authentication" do
      sign_out

      get admin_root_path
      assert_redirected_to new_session_path

      post admin_contracts_path, params: { contract: { reference: "X" } }
      assert_redirected_to new_session_path
    end

    test "lists contracts" do
      get admin_root_path

      assert_response :success
      assert_select "tbody tr", Contract.count
    end

    test "creates a contract and scores it" do
      assert_difference "Contract.count", 1 do
        post admin_contracts_path, params: { contract: {
          entity_id: entities(:fondo).id, contractor_id: contractors(:consorcio).id, reference: "ESC-CD-002-2025",
          object: "Dotación de bibliotecas escolares", modality: "contratacion_directa", signed_on: "2025-05-02",
          initial_value: "90000000", additions_value: "0"
        } }
      end

      contract = Contract.find_by!(reference: "ESC-CD-002-2025")
      assert_redirected_to contract_path(contract)
      assert_equal %w[direct_award new_contractor], contract.red_flags
    end

    test "re-renders the form with errors" do
      assert_no_difference "Contract.count" do
        post admin_contracts_path, params: { contract: { entity_id: entities(:fondo).id, reference: "", initial_value: "0" } }
      end

      assert_response :unprocessable_content
      assert_select ".form-errors"
    end

    test "updates a contract and reassesses it" do
      patch admin_contract_path(contracts(:food)), params: { contract: { additions_value: "60000000" } }

      assert_redirected_to contract_path(contracts(:food))
      assert_includes contracts(:food).reload.red_flags, "additions_over_cap"
    end

    test "destroys a contract" do
      assert_difference "Contract.count", -1 do
        delete admin_contract_path(contracts(:kits))
      end

      assert_redirected_to admin_root_path
      assert_equal 0, entities(:fondo).reload.contracted_value
    end
  end
end
