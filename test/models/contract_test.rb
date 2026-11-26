require "test_helper"

class ContractTest < ActiveSupport::TestCase
  def build_contract(**attributes)
    entities(:fondo).contracts.build({
      contractor: contractors(:nutrir), reference: "ESC-MC-002-2024", object: "Suministro de refrigerios escolares",
      modality: :minima_cuantia, signed_on: Date.new(2024, 2, 1), initial_value: 30_000_000, bidders_count: 2
    }.merge(attributes))
  end

  test "is valid with the required attributes" do
    assert build_contract.valid?
  end

  test "rejects non positive values, negative additions and zero bidders" do
    contract = build_contract(initial_value: 0, additions_value: -1, bidders_count: 0)

    assert_not contract.valid?
    assert contract.errors.added?(:initial_value, :greater_than, value: 0, count: 0)
    assert contract.errors.added?(:additions_value, :greater_than_or_equal_to, value: -1, count: 0)
    assert contract.errors.added?(:bidders_count, :greater_than, value: 0, count: 0)
  end

  test "rejects unknown modalities and end dates before the start" do
    contract = build_contract(modality: "subasta_secreta", start_on: Date.new(2024, 3, 1), end_on: Date.new(2024, 2, 1))

    assert_not contract.valid?
    assert contract.errors.added?(:modality, :inclusion, value: "subasta_secreta")
    assert contract.errors.added?(:end_on, :before_start_on)
  end

  test "references are unique per entity" do
    assert_not build_contract(reference: contracts(:kits).reference).valid?
    assert entities(:san_gabriel).contracts.build(build_contract(reference: contracts(:kits).reference).attributes.except("id", "entity_id")).valid?
  end

  test "saving a contract reassesses its entity" do
    contract = build_contract(bidders_count: 1)
    contract.save!

    assert_equal %w[single_bidder], contract.reload.red_flags
    assert_equal 20, contract.risk_score
    assert_operator entities(:fondo).reload.risk_index, :>, 0
  end

  test "moving a contract reassesses both entities" do
    entities(:san_gabriel).reassess!
    contracts(:road).update!(entity: entities(:fondo))

    assert_equal 0, entities(:san_gabriel).reload.contracts.where(reference: contracts(:road).reference).count
    assert_operator entities(:fondo).reload.risk_index, :>, 0
    assert_equal contracts(:placa).total_value + contracts(:food).total_value + contracts(:legal).total_value,
      entities(:san_gabriel).contracted_value
  end

  test "flagged_with filters by red flag stored in the json column" do
    entities(:san_gabriel).reassess!

    assert_equal [ contracts(:road) ], Contract.flagged_with(:single_bidder).to_a
    assert_equal [ contracts(:legal), contracts(:placa) ].sort, Contract.flagged_with("direct_award").to_a.sort
  end

  test "search matches reference and object, escaping like wildcards" do
    assert_equal [ contracts(:food) ], Contract.search("alimentación").to_a
    assert_equal [ contracts(:kits) ], Contract.search("ESC-SA").to_a
    assert_empty Contract.search("100%")
  end

  test "additions ratio and total value" do
    assert_in_delta 0.6, contracts(:road).additions_ratio
    assert_equal 1_600_000_000, contracts(:road).total_value
  end
end
