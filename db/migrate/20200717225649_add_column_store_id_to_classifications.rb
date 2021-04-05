class AddColumnStoreIdToClassifications < ActiveRecord::Migration[6.0]
  def change
    add_column :classifications, :store_id, :integer
  end
end
