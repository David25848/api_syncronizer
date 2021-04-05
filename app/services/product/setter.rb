# frozen_string_literal: true

# Setter class for get a product instance
class Product::Setter
  # Loop for each products from one store api
  def self.sync_products_from_api(store, run_sync)
    api_products = run_sync.api_products
    Rails.logger.info '===> Saving products from API to Rails'
    delete_not_found_products_in_api(api_products, store)
    # select only saved products
    saved_api_products = api_products.select { |product| saved_product(product, store) }
    no_saved_api_products = (api_products - saved_api_products)
    Rails.logger.error "!!! ERROR: Cannot save products for store #{store.sku}: #{no_saved_api_products.map { |x| x['sku'].to_s}}"
    run_sync.update(products_saved: saved_api_products, api_products_errors: no_saved_api_products)
  end

  # Set one product for get all properties
  def self.saved_product(product, store)
    product = Product::Getter.new(product, store).product
    if product.invalid?
      Rails.logger.error "!!! ERROR: Product can't be saved #{product.sku}: #{product.errors.messages}\n"
      ProductError.find_or_create_by_sku(product)
      false
    else
      product.save # Return true/false
    end
  end

  def self.delete_duplicated_products(store)
    Rails.logger.info "===> Delete duplicated products from #{store.sku} API:\n"
    woo_products = store.woo_products

    deleted_duplicated_products = []

    woo_products.each_with_index do |woo_product, index|
      same_sku_products = woo_products.select { |x| x['sku'].to_s == woo_product['sku'].to_s }

      next unless same_sku_products.size > 1

      Rails.logger.info "##{index}: Hay #{same_sku_products.size} con el mismo sku: #{same_sku_products.map { |x| { sku: x['sku'], id: x['id'], slug: x['slug'] } }}"
      original_slug = same_sku_products.map { |x| x['slug'] }.min
      original_product = same_sku_products.find { |x| x['slug'] == original_slug }
      woo_duplicated_products_ids = same_sku_products.map { |x| x['id'] } - [original_product['id']]
      woo_duplicated_products_ids.each do |woo_id|
        product = store.woo_store.delete("products/#{woo_id}", force: true).parsed_response
        Rails.logger.info "##{index}: DELETED #{product['sku']} with slug: #{product['slug']}"
      rescue JSON::ParserError
        Rails.logger.error "!!! ERROR: Cannot delete #{woo_product['sku']}"
      end
    end

    Rails.logger.info "\n#===========> Productos duplicados recorridos = #{woo_products.size}"
    Rails.logger.info "\n#===========> Productos duplicados borrados = #{deleted_duplicated_products.size}\n"
  end

  # Delete products not found in API Cimo
  def self.delete_not_found_products_in_api(api_products, store)
    woo_store = store.woo_store
    Rails.logger.info "===> Delete not found products from #{store.sku} API:\n"
    woo_products = store.woo_products

    deleted_products = []

    woo_products.each do |woo_product|
      api_product = api_products.find { |item| item['sku'].to_s.strip == woo_product['sku'].to_s } # Search in API

      Rails.logger.info "Found Product in API OR delete in Woo? #{woo_product&.dig('sku')} = #{api_product ? 'FOUND' : 'DELETE'}"
      next if api_product.present?

      deleted_products << api_product
      begin
        woo_store.delete("products/#{woo_product['id']}", force: true).parsed_response
      rescue JSON::ParserError
        Rails.logger.error "!!! ERROR: Cannot delete #{woo_product['sku']}"
      end
      Rails.logger.info "Deleting product from woo #{woo_product['id']}"
      rails_product = Product.find_by(sku: woo_product['sku'])
      rails_product ||= Product.find_by(woocommerce_id: woo_product['id'])
      rails_product&.destroy
      Rails.logger.info "DELETED in Woo and Rails: #{woo_product['sku']}"
    end

    Rails.logger.info "\n#===========> Productos recorridos = #{woo_products.size}"
    Rails.logger.info "\n#===========> Productos borrados = #{deleted_products.size}\n"
  end
end
