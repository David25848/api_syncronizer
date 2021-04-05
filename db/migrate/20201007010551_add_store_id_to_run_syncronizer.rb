class AddStoreIdToRunSyncronizer < ActiveRecord::Migration[6.0]
  def change
    add_reference :run_syncronizers, :store, null: false, foreign_key: true
  end
end
