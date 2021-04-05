class RemoveUniqueConstraintFromIndexSubcategoriesOnSlug < ActiveRecord::Migration[6.0]
  def change
  	remove_index :subcategories, :slug
  	add_index :subcategories, :slug
  end
end
