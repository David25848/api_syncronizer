class CreateStoreClassifications < ActiveRecord::Migration[6.0]
  def change
    create_table :store_classifications do |t|
      t.references :store, null: false, foreign_key: true
      t.references :classification, null: false, foreign_key: true

      t.timestamps
    end
  end
end
