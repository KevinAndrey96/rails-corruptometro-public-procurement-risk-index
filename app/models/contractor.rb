class Contractor < ApplicationRecord
  CITIZEN_ID_FORMAT = /\A\d{6,10}\z/

  enum :document_type, { nit: 0, cc: 1 }, validate: true

  has_many :contracts, dependent: :restrict_with_error
  has_many :entities, -> { distinct }, through: :contracts

  normalizes :name, with: ->(value) { value.squish }
  normalizes :document_number, with: ->(value) { value.delete(" .") }

  validates :name, presence: true, length: { maximum: 150 }
  validates :document_number, uniqueness: { scope: :document_type }
  validates :document_number, nit: true, if: :nit?
  validates :document_number, format: { with: CITIZEN_ID_FORMAT }, if: :cc?
  validates :incorporated_on, absence: true, if: :cc?
  validate :incorporated_on_not_in_the_future

  after_update_commit :reassess_entities, if: :saved_change_to_incorporated_on?

  def to_param
    "#{id}-#{name.parameterize}"
  end

  private
    def incorporated_on_not_in_the_future
      errors.add(:incorporated_on, :in_the_future) if incorporated_on&.future?
    end

    def reassess_entities
      entities.find_each(&:reassess!)
    end
end
