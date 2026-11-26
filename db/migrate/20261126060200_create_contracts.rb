class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :entity, null: false, foreign_key: true
      t.references :contractor, null: false, foreign_key: true
      t.string :reference, null: false, limit: 60
      t.text :object, null: false
      t.integer :modality, null: false
      t.date :signed_on, null: false
      t.date :start_on
      t.date :end_on
      t.bigint :initial_value, null: false
      t.bigint :additions_value, null: false, default: 0
      t.integer :bidders_count
      t.integer :risk_score, null: false, default: 0
      t.json :red_flags, null: false, default: []

      t.timestamps
    end

    add_index :contracts, %i[entity_id reference], unique: true
    add_index :contracts, :risk_score
    add_index :contracts, :signed_on
    add_check_constraint :contracts, "initial_value > 0", name: "contracts_initial_value_positive"
    add_check_constraint :contracts, "additions_value >= 0", name: "contracts_additions_value_not_negative"
    add_check_constraint :contracts, "bidders_count IS NULL OR bidders_count > 0", name: "contracts_bidders_count_positive"
    add_check_constraint :contracts, "risk_score BETWEEN 0 AND 100", name: "contracts_risk_score_range"
  end
end
