require "csv"

# Imports contracts from a CSV whose columns follow the SECOP II open data naming.
# Entities and contractors are upserted by NIT and document, contracts by entity and reference.
# Each row is atomic: an invalid row is reported and skipped, the valid ones are kept.
class ContractImport
  include ActiveModel::Model

  InvalidValue = Class.new(StandardError)

  Failure = Data.define(:line, :messages)

  Result = Data.define(:created, :updated, :failures) do
    def processed
      created + updated
    end

    def success?
      failures.empty?
    end
  end

  REQUIRED_HEADERS = %w[
    nombre_entidad nit_entidad orden departamento referencia_del_contrato objeto_del_contrato
    modalidad_de_contratacion fecha_de_firma valor_del_contrato proveedor_adjudicado
    tipodocproveedor documento_proveedor
  ].freeze

  OPTIONAL_HEADERS = %w[
    fecha_de_inicio_del_contrato fecha_de_fin_del_contrato valor_adiciones numero_de_oferentes
    fecha_constitucion_proveedor
  ].freeze

  MAX_BYTES = 5.megabytes
  MAX_ROWS = 10_000

  MODALITIES = {
    "licitacion" => :licitacion_publica,
    "seleccion abreviada" => :seleccion_abreviada,
    "concurso de meritos" => :concurso_de_meritos,
    "minima cuantia" => :minima_cuantia,
    "contratacion directa" => :contratacion_directa,
    "contratacion regimen especial" => :regimen_especial,
    "regimen especial" => :regimen_especial
  }.freeze

  LEVELS = {
    "nacional" => :national,
    "departamental" => :departmental,
    "municipal" => :municipal,
    "territorial" => :municipal,
    "distrital" => :municipal
  }.freeze

  DOCUMENT_TYPES = { "nit" => :nit, "cc" => :cc, "cedula de ciudadania" => :cc }.freeze

  attr_reader :content

  validate :content_present
  validate :content_within_limits
  validate :headers_present

  def initialize(content:)
    @content = normalize_encoding(content.to_s)
  end

  def call
    created = 0
    updated = 0
    failures = []
    entity_ids = Set.new

    Current.set(bulk_import: true) do
      rows.each.with_index(2) do |row, line|
        contract, new_record = import_row(row)
        entity_ids << contract.entity_id
        new_record ? created += 1 : updated += 1
      rescue ActiveRecord::RecordInvalid => error
        failures << Failure.new(line: line, messages: error.record.errors.full_messages)
      rescue InvalidValue => error
        failures << Failure.new(line: line, messages: [ error.message ])
      end
    end

    Entity.where(id: entity_ids.to_a).find_each(&:reassess!)

    Result.new(created: created, updated: updated, failures: failures)
  end

  private
    def rows
      @rows ||= CSV.parse(content, headers: true, header_converters: ->(header) { header.to_s.strip.downcase })
    rescue CSV::MalformedCSVError
      @rows = nil
    end

    def import_row(row)
      Contract.transaction do
        entity = upsert_entity(row)
        contractor = upsert_contractor(row)
        contract = entity.contracts.find_or_initialize_by(reference: row["referencia_del_contrato"].to_s.squish)
        new_record = contract.new_record?

        contract.update!(
          contractor: contractor,
          object: row["objeto_del_contrato"],
          modality: lookup(MODALITIES, row["modalidad_de_contratacion"], :modality),
          signed_on: parse_date(row["fecha_de_firma"], :signed_on),
          start_on: parse_date(row["fecha_de_inicio_del_contrato"], :start_on),
          end_on: parse_date(row["fecha_de_fin_del_contrato"], :end_on),
          initial_value: parse_money(row["valor_del_contrato"]),
          additions_value: parse_money(row["valor_adiciones"]) || 0,
          bidders_count: row["numero_de_oferentes"].presence&.to_i
        )

        [ contract, new_record ]
      end
    end

    def upsert_entity(row)
      entity = Entity.find_or_initialize_by(nit: row["nit_entidad"].to_s.delete(" ."))
      entity.update!(
        name: row["nombre_entidad"],
        level: lookup(LEVELS, row["orden"], :level),
        department: row["departamento"]
      )
      entity
    end

    def upsert_contractor(row)
      contractor = Contractor.find_or_initialize_by(
        document_type: lookup(DOCUMENT_TYPES, row["tipodocproveedor"], :document_type),
        document_number: row["documento_proveedor"].to_s.delete(" .")
      )
      contractor.update!(
        name: row["proveedor_adjudicado"],
        incorporated_on: parse_date(row["fecha_constitucion_proveedor"], :incorporated_on)
      )
      contractor
    end

    def lookup(table, raw, attribute)
      value = I18n.transliterate(raw.to_s).downcase.squish
      match = table.find { |prefix, _| value.start_with?(prefix) }
      raise InvalidValue, I18n.t("contract_import.unknown_value", attribute: attribute_name(attribute), value: raw) if match.nil?

      match.last
    end

    def parse_date(raw, attribute)
      value = raw.to_s.strip
      return if value.blank?

      value.include?("/") ? Date.strptime(value, "%d/%m/%Y") : Date.iso8601(value)
    rescue Date::Error
      raise InvalidValue, I18n.t("contract_import.invalid_date", attribute: attribute_name(attribute), value: raw)
    end

    # Accepts "1234567", "1.234.567", "$ 1.234.567,00" and "1234567.00"; thousand groups always have three digits.
    def parse_money(raw)
      integer_part = raw.to_s.strip.split(",").first.to_s.sub(/\.\d{1,2}\z/, "")
      digits = integer_part.gsub(/\D/, "")

      digits.presence&.to_i
    end

    def attribute_name(attribute)
      I18n.t("contract_import.columns.#{attribute}")
    end

    def normalize_encoding(raw)
      text = raw.dup.force_encoding(Encoding::UTF_8)
      text = raw.dup.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8) unless text.valid_encoding?

      text.delete_prefix("\uFEFF")
    end

    def content_present
      errors.add(:base, :blank_file) if content.blank?
    end

    def content_within_limits
      errors.add(:base, :file_too_large, megabytes: MAX_BYTES / 1.megabyte) if content.bytesize > MAX_BYTES
    end

    def headers_present
      return if content.blank? || errors.any?
      return errors.add(:base, :malformed_csv) if rows.nil?
      return errors.add(:base, :too_many_rows, count: MAX_ROWS) if rows.size > MAX_ROWS

      missing = REQUIRED_HEADERS - rows.headers.compact
      errors.add(:base, :missing_headers, headers: missing.join(", ")) if missing.any?
    end
end
