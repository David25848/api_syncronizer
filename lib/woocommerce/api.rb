# frozen_string_literal: true

# Methods extension for woocommerce_api gem
WooCommerce::API.class_eval do
  def products(page = 1)
    @woo_products = []

    loop do
      products = get('products', page: page, per_page: 100).parsed_response
      @woo_products += products
      page += 1
      break if products.size < 100
    end

    @woo_products
  end

  def categories(page = 1)
    get('products/categories', page: page, per_page: 100).parsed_response
  rescue Net::ReadTimeout
    Rails.logger.error '!!! ERROR: Cannot get categories from WooCommerce'
    nil
  rescue StandardError => e
    Rails.logger.error "!!! ERROR: Unknown error: #{e}"
    nil
  end

  def create_category(data)
    post('products/categories', data).parsed_response
  end

  def build_in_batch(store, batch_size = 10, run_sync)
    @woo_products = store.woo_products

    # Because woocommerce only permit create or update in bach from 100 size
    store.products.find_in_batches(batch_size: batch_size) do |objects|
      Rails.logger.info "Loading to woocommerce #{objects.size} products"

      # separate which products will be to create and which
      # to update from woocommerce products
      rails_products = Product.where(id: objects.map(&:id))
      products = rails_products.define_create_and_update(@woo_products)

      # build the correct woocommerce batch format
      @batch_json = Product.build_json(products[:to_create], products[:to_update])
      Rails.logger.info "====> Products to create in #{store.name}:\n#{@batch_json[:create].map { |x| x['sku'].to_s }}"
      Rails.logger.info "====> Products to update in #{store.name}:\n#{@batch_json[:update].map { |x| x['sku'].to_s }}}"

      # Send data to create and update to woocommerce

      product_creating_tries = 1
      res_woo = nil
      while res_woo.nil? && product_creating_tries <= 3
        begin
          res_woo = post('products/batch', @batch_json).parsed_response
        rescue Net::ReadTimeout
          skus = (@batch_json[:create].map { |x| x[:sku] } + @batch_json[:update].map { |x| x[:sku] }).flatten
          Rails.logger.error "!!! ERROR: Cannot load products to WooCommerce in #{store.sku}: #{skus}\nRetry: #{product_creating_tries}"
        rescue StandardError => e
          Rails.logger.error "!!! ERROR: Unknown error: #{e} in #{store.sku}"
        end
        product_creating_tries += 1
      end

      next unless res_woo

      res_woo['create'] ||= []
      res_woo['update'] ||= []

      Rails.logger.info "====> Response:\n#{res_woo}"
      Rails.logger.info "====> Created products:\n#{(res_woo['create'])}\n"
      Rails.logger.info "====> Updated products:\n#{(res_woo['update'])}\n"

      products = (res_woo['create'] + res_woo['update']).flatten
      Rails.logger.info "====> PRODUCTOS QUE SE GUARDARON EN WOOCOMMERCE: #{products.size}"
      create_and_update_variation(store, products)
      run_sync.update(woo_products_saved: products)  
    end
  end

  def create_and_update_variation(store, products)
    products.map do |product|
      rails_product = Product.find_by(sku: product['sku'])
      next unless rails_product

      Rails.logger.info rails_product ? "ENCONTRADO #{rails_product.build_json_variations}" : 'IGNORADO'

      rails_product&.update(woocommerce_id: product['id'])

      rails_product.build_json_variations&.each do |variation|
        begin
          Rails.logger.info "===> Getting variation #{variation[:sku]} for product #{rails_product.sku}"
          woo_variation = store.woo_store.get("products/#{product['id']}/variations", { sku: variation[:sku] }).parsed_response&.first
        rescue StandardError
          Rails.logger.error "!!! ERROR: Cannot get variation #{variation[:sku]} for product #{rails_product.sku}"
        end
        if woo_variation&.dig('id')
          # Rails.logger.info "Updating variation to Woo: #{variation}"
          # Update variation
          begin
            Rails.logger.info "===> Updating variation #{variation[:sku]} for product #{rails_product.sku}"
            updated_variation = store.woo_store.put("products/#{product['id']}/variations/#{woo_variation['id']}", variation).parsed_response
            if updated_variation&.dig('id')
              Rails.logger.info "===> UPDATED variation #{variation[:sku]} for product #{rails_product.sku}"
            else
              Rails.logger.info "!!! Error: Failed updating variation #{variation[:sku]} for product #{rails_product.sku}: #{created_variation['message']}"
            end
          rescue StandardError
            Rails.logger.error "!!! ERROR: Cannot update variation #{variation[:sku]} for product #{rails_product.sku}"
          end
          next
        else
          # Rails.logger.info "Creating variation to Woo: #{variation}"
          # Create variation
          begin
            Rails.logger.info "===> Creating variation #{variation[:sku]} for product #{rails_product.sku}"
            created_variation = store.woo_store.post("products/#{product['id']}/variations", variation).parsed_response
            if created_variation&.dig('id')
              Rails.logger.info "===> CREATED variation #{variation[:sku]} for product #{rails_product.sku}"
            else
              Rails.logger.info "!!! Error: Failed creating variation #{variation[:sku]} for product #{rails_product.sku}: #{created_variation['message']}"
            end
          rescue StandardError
            Rails.logger.error "!!! ERROR: Cannot create variation #{variation[:sku]} for product #{rails_product.sku}"
          end
        end
      end
    end
  end
end
