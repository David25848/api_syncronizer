class AddWoocommerceIdsToSubcategories < ActiveRecord::Migration[6.0]
  def change
    add_column :subcategories, :woocommerce_ids, :json, array: true, default: []
  end
end
