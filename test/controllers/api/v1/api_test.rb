require "test_helper"

module Api
  module V1
    class ApiTest < ActionDispatch::IntegrationTest
      setup { Entity.find_each(&:reassess!) }

      test "lists entities ranked by risk with pagination metadata" do
        get api_v1_entities_path

        assert_response :success
        body = response.parsed_body
        assert_equal entities(:san_gabriel).nit, body["data"].first["nit"]
        assert_equal({ "page" => 1, "per_page" => 25, "total_count" => 2, "total_pages" => 1 }, body["meta"])
      end

      test "shows an entity" do
        get api_v1_entity_path(entities(:fondo))

        assert_equal "national", response.parsed_body.dig("data", "level")
      end

      test "filters contracts by flag and minimum score" do
        get api_v1_contracts_path(flag: "single_bidder", min_score: 50)

        data = response.parsed_body["data"]
        assert_equal [ contracts(:road).reference ], data.pluck("reference")
        assert_equal %w[additions_over_cap single_bidder], data.first["red_flags"]
        assert_equal "high", data.first["risk_level"]
      end

      test "never exposes citizen id numbers" do
        get api_v1_contract_path(contracts(:legal))

        assert_response :success
        assert_no_match contractors(:lawyer).document_number, response.body
      end

      test "caps the page size" do
        get api_v1_contracts_path(per_page: 1_000)

        assert_equal Page::MAX_SIZE, response.parsed_body.dig("meta", "per_page")
      end

      test "lists red flags with weights and legal basis" do
        get api_v1_red_flags_path

        flags = response.parsed_body["data"]
        assert_equal 100, flags.sum { |flag| flag["weight"] }
        assert flags.all? { |flag| flag["legal_basis"].present? }
      end

      test "returns json not found" do
        get api_v1_contract_path(id: 0)

        assert_response :not_found
        assert_equal "not_found", response.parsed_body["error"]
      end
    end
  end
end
