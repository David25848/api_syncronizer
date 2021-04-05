# frozen_string_literal: true

require 'open-uri'

# CimoSynchronizer Service for syncronizers stores inventory
class CimoSynchronizer
  # Class method for sync each model in rails to woocommerce
  def self.sync(env, store)
    raise '!!! ERROR: Wrong environment' unless %w[stage production].include?(env)

    # Service to synchronize stores in rails from available API stores
    Store::Service.sync_from_api_to_rails(env, store)

    rails_products = store.products
    api_products   = store.api_products
    woo_products = store.woo_products
    woo_categories = store.woo_categories

    @runsynchronizer = RunSyncronizer.create(
      store_id: store.id,
      start_run_date: DateTime.now,
      products_saved: rails_products,
      api_products: api_products,
      woo_products_saved: woo_products,
      woo_category_saved: woo_categories
    )
    Rails.logger.info "======> Running CimoSynchronizer.sync in #{env}#{' for ' + store&.name if store} at #{Time.now}"
    sleep 5

    # Service to synchronize products in rails from API products
    Product::Parse.sync_rails_from_api(store, @runsynchronizer)

    # once the products have been uploaded, from these records all categories
    # and subcategories are created for each store
    # Service to synchronize available categories from API through products
    Category::Service.sync_from_rails_to_woocommerce(store)

    # Service to synchronize products from rails for each store
    # to woocommerce products
    Store::Service.sync_from_rails_to_woocommerce(store, @runsynchronizer)

    # Delete duplicated products
    Product::Setter.delete_duplicated_products(store)

    # After creating and updating products to every category in WooCommerce
    # this analyze for empty categories and it deletes them
    Category::Service.delete_categories_without_products(store)

    @runsynchronizer.update(
      woo_products_saved: store.woo_products,
      end_run_date: DateTime.now
    )
  end
end
