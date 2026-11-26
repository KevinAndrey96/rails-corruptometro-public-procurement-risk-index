require "test_helper"

class ContractImportTest < ActiveSupport::TestCase
  HEADER = (ContractImport::REQUIRED_HEADERS + ContractImport::OPTIONAL_HEADERS).join(",")

  def row(**overrides)
    values = {
      nombre_entidad: "Alcaldía de Puerto Aurora", nit_entidad: "890481765-8", orden: "Territorial", departamento: "Bolívar",
      referencia_del_contrato: "AUR-SA-010-2025", objeto_del_contrato: "Suministro de kits escolares",
      modalidad_de_contratacion: "Selección abreviada de menor cuantía", fecha_de_firma: "2025-04-10",
      valor_del_contrato: "$ 250.000.000,00", proveedor_adjudicado: "Suministros Integrales del Caribe S.A.S.",
      tipodocproveedor: "NIT", documento_proveedor: "901102938-1", fecha_de_inicio_del_contrato: "15/04/2025",
      fecha_de_fin_del_contrato: "2025-12-15", valor_adiciones: "150000000", numero_de_oferentes: "1",
      fecha_constitucion_proveedor: "2017-05-22"
    }.merge(overrides)

    (ContractImport::REQUIRED_HEADERS + ContractImport::OPTIONAL_HEADERS).map { |header| %("#{values[header.to_sym]}") }.join(",")
  end

  def import(*rows)
    ContractImport.new(content: ([ HEADER ] + rows).join("\n"))
  end

  test "imports the bundled demo dataset without rejected rows" do
    result = ContractImport.new(content: Rails.root.join("db/samples/contratos_demo.csv").read).call

    assert result.success?
    assert_equal 63, result.created
    assert_equal 9, Entity.count
    assert Contract.where(risk_score: 1..).exists?
  end

  test "upserts entities, contractors and contracts and scores them" do
    result = import(row).call

    contract = Contract.find_by!(reference: "AUR-SA-010-2025")
    assert_equal 1, result.created
    assert_equal "seleccion_abreviada", contract.modality
    assert_equal "municipal", contract.entity.level
    assert_equal 250_000_000, contract.initial_value
    assert_equal Date.new(2025, 4, 15), contract.start_on
    assert_equal %w[single_bidder additions_over_cap].sort, contract.red_flags.sort
    assert_equal 50, contract.entity.reload.risk_index
  end

  test "importing the same row twice updates instead of duplicating" do
    import(row).call
    result = import(row(valor_adiciones: "0")).call

    assert_equal 0, result.created
    assert_equal 1, result.updated
    assert_equal %w[single_bidder], Contract.find_by!(reference: "AUR-SA-010-2025").red_flags
  end

  test "reports invalid rows with their line number and keeps the valid ones" do
    result = import(
      row,
      row(referencia_del_contrato: "AUR-XX-1", modalidad_de_contratacion: "Subasta secreta"),
      row(referencia_del_contrato: "AUR-XX-2", nit_entidad: "890481765-9"),
      row(referencia_del_contrato: "AUR-XX-3", fecha_de_firma: "10-04-2025")
    ).call

    assert_equal 1, result.created
    assert_equal [ 3, 4, 5 ], result.failures.map(&:line)
    assert_match "Modalidad no reconocida", result.failures.first.messages.first
    assert_match "NIT", result.failures.second.messages.first
    assert_match "Fecha de firma inválida", result.failures.third.messages.first
    assert_not Entity.exists?(nit: "890481765-9")
  end

  test "rejects files without the required columns" do
    import = ContractImport.new(content: "nombre_entidad,valor\nAlcaldía,1")

    assert_not import.valid?
    assert_match "referencia_del_contrato", import.errors.full_messages.first
  end

  test "rejects empty and oversized files" do
    assert_not ContractImport.new(content: "").valid?

    oversized = ContractImport.new(content: "a" * (ContractImport::MAX_BYTES + 1))
    assert_not oversized.valid?
    assert oversized.errors.added?(:base, :file_too_large, megabytes: 5)
  end

  test "reads latin-1 files and strips the UTF-8 BOM" do
    latin = ([ HEADER, row ].join("\n")).encode(Encoding::ISO_8859_1)

    assert ContractImport.new(content: latin.b).valid?
    assert ContractImport.new(content: "\uFEFF#{HEADER}\n#{row}").valid?
  end

  test "parses colombian and plain money formats" do
    import = ContractImport.new(content: "")

    assert_equal 1_234_567, import.send(:parse_money, "$ 1.234.567,00")
    assert_equal 1_234_567, import.send(:parse_money, "1234567.00")
    assert_equal 1_234_567, import.send(:parse_money, "1.234.567")
    assert_nil import.send(:parse_money, "")
  end
end
