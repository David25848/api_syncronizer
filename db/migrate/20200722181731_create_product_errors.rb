class CreateProductErrors < ActiveRecord::Migration[6.0]
  def change
    create_table :product_errors do |t|
      t.string :sku
      t.text :api
      t.text :woo
      t.boolean :public

      t.timestamps
    end
  end
end
