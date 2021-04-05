# frozen_string_literal: true

# Parse class for loop each store
class Product::Parse
  # Class method for loop items from store anda validate his size
  def self.sync_rails_from_api(store = nil, run_sync)
    if store
      request_api(store, run_sync)
    else
      Store.find_each do |rails_store|
        request_api(rails_store) rescue next
      end
    end
  end

  def self.request_api(store, run_sync)
    Product::Setter.sync_products_from_api(store, run_sync)
  rescue HTTParty::Error => e
    Rails.logger.error "!!! ERROR: HTTParty error: #{e} in #{store&.sku}"
  rescue Net::ReadTimeout
    Rails.logger.error "!!! ERROR: API from #{store.name} is broken: #{store.url_external_api} in #{store&.sku}"
  rescue StandardError => e
    Rails.logger.error "!!! ERROR: Unknown error: #{e} in #{store&.sku}"
  end
end
