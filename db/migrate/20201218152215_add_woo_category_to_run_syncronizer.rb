class AddWooCategoryToRunSyncronizer < ActiveRecord::Migration[6.0]
  def change
    add_column :run_syncronizers, :woo_category_saved, :jsonb
  end
end
