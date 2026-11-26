require "test_helper"

class RiskAssessorTest < ActiveSupport::TestCase
  setup do
    @entity = entities(:san_gabriel)
    @entity.reassess!
  end

  test "flags additions over half the initial value and single bidders in competitive processes" do
    assert_equal %w[additions_over_cap single_bidder], contracts(:road).reload.red_flags
    assert_equal 50, contracts(:road).risk_score
  end

  test "flags direct awards to contractors incorporated less than a year before signing" do
    assert_equal %w[direct_award new_contractor], contracts(:placa).reload.red_flags
    assert_equal 30, contracts(:placa).risk_score
  end

  test "flags direct awards inside the Ley de Garantias window" do
    assert_equal %w[direct_award electoral_restriction], contracts(:legal).reload.red_flags
  end

  test "leaves clean contracts without flags" do
    assert_empty contracts(:food).reload.red_flags
    assert_equal 0, contracts(:food).risk_score
  end

  test "additions of exactly half the initial value are within the legal cap" do
    contracts(:food).update_columns(additions_value: 40_000_000)
    @entity.reassess!

    assert_not_includes contracts(:food).reload.red_flags, "additions_over_cap"
  end

  test "single bidder does not apply to direct awards" do
    contracts(:placa).update_columns(bidders_count: 1)
    @entity.reassess!

    assert_not_includes contracts(:placa).reload.red_flags, "single_bidder"
  end

  test "flags concentration when one contractor holds over 40 percent of the value across five or more contracts" do
    assert_not_includes contracts(:road).reload.red_flags, "contractor_concentration"

    @entity.contracts.create!(contractor: contractors(:nutrir), reference: "GAB-MC-005-2024", object: "Suministro de refrigerios",
      modality: :minima_cuantia, signed_on: Date.new(2024, 8, 1), initial_value: 10_000_000, bidders_count: 2)

    assert_includes contracts(:road).reload.red_flags, "contractor_concentration"
    assert_not_includes contracts(:food).reload.red_flags, "contractor_concentration"
  end

  test "computes the entity index weighted by contract value" do
    contracts = @entity.contracts.reload
    total = contracts.sum(&:total_value)
    expected = contracts.sum { |contract| contract.risk_score * contract.total_value }.fdiv(total).round

    assert_equal expected, @entity.reload.risk_index
    assert_equal total, @entity.contracted_value
  end

  test "an entity without contracts has a zero index" do
    entity = Entity.create!(name: "Personería de Prueba", nit: "860001022-7", level: :municipal, department: "Boyacá")
    entity.reassess!

    assert_equal 0, entity.reload.risk_index
    assert_equal 0, entity.contracted_value
  end
end
