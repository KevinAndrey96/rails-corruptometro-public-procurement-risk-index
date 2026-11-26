class CreateContractors < ActiveRecord::Migration[8.1]
  def change
    create_table :contractors do |t|
      t.string :name, null: false, limit: 150
      t.integer :document_type, null: false
      t.string :document_number, null: false, limit: 11
      t.date :incorporated_on

      t.timestamps
    end

    add_index :contractors, %i[document_type document_number], unique: true
  end
end
