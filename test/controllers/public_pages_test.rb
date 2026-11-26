require "test_helper"

class PublicPagesTest < ActionDispatch::IntegrationTest
  setup do
    Entity.find_each(&:reassess!)
  end

  test "dashboard shows headline figures and rankings without signing in" do
    get root_path

    assert_response :success
    assert_select "h1", "Panel de riesgo"
    assert_select ".kpi", 4
    assert_select "a[href=?]", entity_path(entities(:san_gabriel))
    assert_select "a[href=?]", contract_path(contracts(:road))
  end

  test "dashboard explains how to load data when there are no contracts" do
    Contract.delete_all

    get root_path

    assert_select ".empty-state", /importarlos desde un CSV/
  end

  test "entities ranking filters by department and level" do
    get entities_path(department: "Antioquia")
    assert_select ".row", 1
    assert_select ".row-title", entities(:san_gabriel).name

    get entities_path(level: "national")
    assert_select ".row-title", entities(:fondo).name
  end

  test "entity page shows its contracts and main contractors" do
    get entity_path(entities(:san_gabriel))

    assert_response :success
    assert_select "h1", entities(:san_gabriel).name
    assert_select ".row", 4
    assert_select "a[href=?]", contractor_path(contractors(:horizonte).id)
  end

  test "contracts listing filters by flag, modality, department and text" do
    get contracts_path(flag: "single_bidder")
    assert_select ".row-title", text: contracts(:road).reference, count: 1
    assert_select ".row", 1

    get contracts_path(modality: "seleccion_abreviada")
    assert_select ".row-title", contracts(:kits).reference

    get contracts_path(department: "Antioquia", q: "jurídica")
    assert_select ".row-title", contracts(:legal).reference

    get contracts_path(flag: "<script>", modality: "nope")
    assert_select ".row", Contract.count
  end

  test "contract page explains each red flag with its legal basis" do
    get contract_path(contracts(:road))

    assert_response :success
    assert_select ".flag", 2
    assert_select ".flag", /Ley 80 de 1993/
    assert_select ".badge", /50/
  end

  test "contractor page masks citizen ids" do
    get contractor_path(contractors(:lawyer))

    assert_response :success
    assert_select "p.muted", /CC \*\*\*\*8193/
    assert_no_match contractors(:lawyer).document_number, response.body
  end

  test "methodology lists flags, weights and electoral windows" do
    get methodology_path

    assert_response :success
    assert_select ".flag", RedFlag.all.size
    assert_select "li", /31 de enero de 2026/
  end

  test "unknown records return not found" do
    get contract_path(id: 0)

    assert_response :not_found
  end
end
