class CreateRunSyncronizers < ActiveRecord::Migration[6.0]
  def change
    create_table :run_syncronizers do |t|
      t.jsonb :products_saved, default: {}
      t.jsonb :api_products, default: {}
      t.jsonb :woo_products_saved, default: {}
      t.jsonb :api_products_errors, default: {}
      t.jsonb :products_errors, default: {}
      t.datetime :start_run_date, precision: 6
      t.datetime :end_run_date, precision: 6

      t.timestamps
    end
  end
end
