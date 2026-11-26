require "test_helper"

class EntityTest < ActiveSupport::TestCase
  test "requires a valid NIT, name, level and department" do
    entity = Entity.new(name: " ", nit: "890981234-5", level: "galactic", department: "")

    assert_not entity.valid?
    assert entity.errors.added?(:nit, :invalid_nit)
    assert entity.errors.added?(:name, :blank)
    assert entity.errors.added?(:department, :blank)
    assert entity.errors.added?(:level, :inclusion, value: "galactic")
  end

  test "normalizes NIT separators and squishes names" do
    entity = Entity.new(nit: "860.001.022-7", name: "  Personería   de Prueba ")

    assert_equal "860001022-7", entity.nit
    assert_equal "Personería de Prueba", entity.name
  end

  test "NIT is unique" do
    assert_not Entity.new(name: "Duplicada", nit: entities(:fondo).nit, level: :national, department: "Bogotá D.C.").valid?
  end

  test "cannot be destroyed while it has contracts" do
    assert_not entities(:fondo).destroy
    assert entities(:fondo).errors.any?
  end

  test "parameterizes with the name for readable urls" do
    assert_equal "#{entities(:fondo).id}-fondo-nacional-de-dotacion-escolar", entities(:fondo).to_param
  end
end
