class AddWoocommerceIdsToClassifications < ActiveRecord::Migration[6.0]
  def change
    add_column :classifications, :woocommerce_ids, :json, array: true, default: []
  end
end
