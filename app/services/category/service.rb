# frozen_string_literal: true

# Category Service class for sync subcategories in woocommerce
class Category::Service
  def self.sync_from_rails_to_woocommerce(store = nil)
    if store
      load_from_rails_to_woocommerce(store)
    else
      Store.find_each do |rails_store|
        load_from_rails_to_woocommerce(rails_store)
      end
    end
  end

  def self.load_from_rails_to_woocommerce(store)
    @store            = store
    @woo_store        = WooCommerce::API.new(*@store.data_to_woocommerce)
    @woo_categories   = @woo_store.categories
    @categories       = store.classifications_by_products
    @subcategories    = store.subcategories_by_products

    @store.classifications.find_each do |classification|
      woo_category =
        @woo_categories.find { |x| x['slug'] == classification.slug }

      # Classifications are father categories in woocommerce
      classification.create_or_update_woocommerce_id(woo_category)

      # Get only subcategories from this store in this classification
      subcategories = classification.subcategories.where(id: @subcategories)

      Rails.logger.info "\n=====> Loading #{classification.name} subcategories" if subcategories.present?

      subcategories.each do |subcategory|
        # Validates if subcategory exists in category woocommerce
        woo_subcategory =
          @woo_categories.find { |x| x['parent'] == classification.woocommerce_id && x['slug'] == subcategory.slug }

        # Classifications are father categories in woocommerce
        # Subcategories are child categories in woocommerce, and also
        # categories from api cimo
        if woo_subcategory.blank?
          subcategory.create_in_woocommerce
        else
          subcategory.update_by_woocommerce(woo_subcategory)
        end
      end
    end
  end

  def self.delete_categories_without_products(store = nil)
    if store
      delete_in_store(store)
    else
      Store.find_each do |rails_store|
        delete_in_store(rails_store)
      end
    end
  end

  def self.delete_in_store(store)
    @woo_store        = WooCommerce::API.new(*store.data_to_woocommerce)
    @woo_categories   = @woo_store.categories
    woo_categories_without_products = @woo_categories.select { |x| x['count'].to_i.zero? }
    Rails.logger.info "===> Deleting #{woo_categories_without_products.size} categories without products: #{woo_categories_without_products.map { |x| x['slug'] }}"
    woo_categories_without_products.each do |woo_category|
      Rails.logger.info "===> Deleting #{woo_category['name']}"
      @woo_store.delete("products/categories/#{woo_category['id']}", force:true)
      Rails.logger.info ">>>> Deleted #{woo_category['name']}!"
    end
  end
end
