class CreateEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :entities do |t|
      t.string :name, null: false, limit: 150
      t.string :nit, null: false, limit: 11
      t.integer :level, null: false
      t.string :department, null: false, limit: 60
      t.integer :risk_index, null: false, default: 0
      t.bigint :contracted_value, null: false, default: 0
      t.integer :contracts_count, null: false, default: 0

      t.timestamps
    end

    add_index :entities, :nit, unique: true
    add_index :entities, :risk_index
    add_check_constraint :entities, "risk_index BETWEEN 0 AND 100", name: "entities_risk_index_range"
  end
end
