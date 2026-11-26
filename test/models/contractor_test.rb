require "test_helper"

class ContractorTest < ActiveSupport::TestCase
  test "companies need a valid NIT and people a citizen id" do
    assert_not Contractor.new(name: "Empresa", document_type: :nit, document_number: "900456123-2").valid?
    assert_not Contractor.new(name: "Persona", document_type: :cc, document_number: "12-34").valid?
    assert Contractor.new(name: "Persona", document_type: :cc, document_number: "1020304050").valid?
  end

  test "people have no incorporation date and companies none in the future" do
    person = Contractor.new(name: "Persona", document_type: :cc, document_number: "1020304050", incorporated_on: Date.new(2020, 1, 1))
    company = Contractor.new(name: "Empresa", document_type: :nit, document_number: "860001022-7", incorporated_on: Date.current + 1)

    assert_not person.valid?
    assert person.errors.added?(:incorporated_on, :present)
    assert_not company.valid?
    assert company.errors.added?(:incorporated_on, :in_the_future)
  end

  test "documents are unique per type" do
    assert_not Contractor.new(name: "Copia", document_type: :nit, document_number: contractors(:horizonte).document_number).valid?
  end

  test "changing the incorporation date reassesses the entities it contracts with" do
    entities(:san_gabriel).reassess!
    assert_not_includes contracts(:road).reload.red_flags, "new_contractor"

    contractors(:horizonte).update!(incorporated_on: Date.new(2025, 1, 15))

    assert_includes contracts(:road).reload.red_flags, "new_contractor"
  end
end
