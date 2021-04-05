class AddColumnWoocommerceIdToClassifications < ActiveRecord::Migration[6.0]
  def change
    add_column :classifications, :woocommerce_id, :integer
  end
end
