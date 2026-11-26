class Contract < ApplicationRecord
  COMPETITIVE_MODALITIES = %w[licitacion_publica seleccion_abreviada concurso_de_meritos minima_cuantia].freeze

  enum :modality, {
    licitacion_publica: 0,
    seleccion_abreviada: 1,
    concurso_de_meritos: 2,
    minima_cuantia: 3,
    contratacion_directa: 4,
    regimen_especial: 5
  }, validate: true

  belongs_to :entity, counter_cache: true
  belongs_to :contractor

  normalizes :reference, with: ->(value) { value.squish }
  normalizes :object, with: ->(value) { value.squish }

  validates :reference, presence: true, length: { maximum: 60 }, uniqueness: { scope: :entity_id }
  validates :object, presence: true, length: { maximum: 2_000 }
  validates :signed_on, presence: true
  validates :initial_value, numericality: { only_integer: true, greater_than: 0 }
  validates :additions_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :bidders_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :end_on_after_start_on

  after_commit :reassess_entities, unless: -> { Current.bulk_import }

  scope :riskiest, -> { order(risk_score: :desc, signed_on: :desc) }
  scope :recent, -> { order(signed_on: :desc, id: :desc) }
  scope :flagged_with, ->(flag) { where("EXISTS (SELECT 1 FROM json_each(contracts.red_flags) WHERE json_each.value = ?)", flag.to_s) }

  def self.search(query)
    return all if query.blank?

    term = "%#{sanitize_sql_like(query.strip)}%"
    where("contracts.reference LIKE :term OR contracts.object LIKE :term", term: term)
  end

  def competitive?
    modality.in?(COMPETITIVE_MODALITIES)
  end

  def total_value
    initial_value.to_i + additions_value.to_i
  end

  def additions_ratio
    return 0.0 if initial_value.to_i.zero?

    additions_value.to_i.fdiv(initial_value)
  end

  def flags
    RedFlag.where(red_flags)
  end

  def risk_level
    RiskLevel.for(risk_score)
  end

  private
    def end_on_after_start_on
      return if start_on.blank? || end_on.blank?

      errors.add(:end_on, :before_start_on) if end_on < start_on
    end

    def reassess_entities
      Entity.where(id: [ entity_id, entity_id_previously_was ].compact.uniq).find_each(&:reassess!)
    end
end
