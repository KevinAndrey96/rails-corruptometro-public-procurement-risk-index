require "test_helper"

module Admin
  class CatalogControllersTest < ActionDispatch::IntegrationTest
    setup { sign_in_as(users(:one)) }

    test "creates an entity with a valid NIT" do
      assert_difference "Entity.count", 1 do
        post admin_entities_path, params: { entity: { name: "Personería de Prueba", nit: "860.001.022-7", level: "municipal", department: "Boyacá" } }
      end

      assert_redirected_to admin_entities_path
      assert Entity.exists?(nit: "860001022-7")
    end

    test "rejects an entity with a wrong check digit" do
      assert_no_difference "Entity.count" do
        post admin_entities_path, params: { entity: { name: "Personería de Prueba", nit: "860001022-1", level: "municipal", department: "Boyacá" } }
      end

      assert_response :unprocessable_content
      assert_select ".form-errors", /dígito de verificación/
    end

    test "updates an entity" do
      patch admin_entity_path(entities(:fondo)), params: { entity: { department: "Cundinamarca" } }

      assert_redirected_to admin_entities_path
      assert_equal "Cundinamarca", entities(:fondo).reload.department
    end

    test "lists and creates contractors" do
      get admin_contractors_path
      assert_select "tbody tr", Contractor.count

      assert_difference "Contractor.count", 1 do
        post admin_contractors_path, params: { contractor: { name: "Jorge Martínez", document_type: "cc", document_number: "79563214" } }
      end

      assert_redirected_to admin_contractors_path
    end

    test "edits a contractor" do
      get edit_admin_contractor_path(contractors(:nutrir))
      assert_response :success

      patch admin_contractor_path(contractors(:nutrir)), params: { contractor: { name: "Nutrir S.A.S." } }
      assert_equal "Nutrir S.A.S.", contractors(:nutrir).reload.name
    end
  end
end
