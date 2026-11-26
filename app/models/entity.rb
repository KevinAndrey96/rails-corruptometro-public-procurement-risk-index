class Entity < ApplicationRecord
  enum :level, { national: 0, departmental: 1, municipal: 2 }, validate: true

  has_many :contracts, dependent: :restrict_with_error
  has_many :contractors, -> { distinct }, through: :contracts

  normalizes :name, :department, with: ->(value) { value.squish }
  normalizes :nit, with: ->(value) { value.delete(" .") }

  validates :name, presence: true, length: { maximum: 150 }
  validates :department, presence: true, length: { maximum: 60 }
  validates :nit, uniqueness: true, nit: true

  scope :ranked, -> { order(risk_index: :desc, contracted_value: :desc, name: :asc) }
  scope :with_contracts, -> { where(contracts_count: 1..) }

  def self.departments
    distinct.order(:department).pluck(:department)
  end

  def risk_level
    RiskLevel.for(risk_index)
  end

  def reassess!
    RiskAssessor.new(self).call
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end
end
