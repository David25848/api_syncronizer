# frozen_string_literal: true

require 'open-uri'

# Store Service for syncronizers stores
class Store::Service
  # Sync stores from api cimo
  def self.sync_from_api_to_rails(env = 'production', store = nil)
    # TODO: change por HTTParty when exists store endpoint
    response = File.open("#{Rails.root}/docs/cimo_api_stores_#{env}.json").read
    response = JSON.parse(response).symbolize_keys

    if store
      json_store = response[:data].find { |x| x['sku'].to_s == store.sku }
      Store.initialize_for(json_store.symbolize_keys)
    else
      response[:data].each do |json_store|
        Store.initialize_for(json_store.symbolize_keys)
      end
    end
  end

  # Sync products for each store from rails through cimo api
  def self.sync_from_rails_to_woocommerce(store = nil, run_sync)
    if store
      store.woo_store.build_in_batch(store, run_sync)
    else
      Store.find_each do |rails_store|
        Rails.logger.info "Uploading products from RailsStore #{rails_store.name} to WooStore"
        rails_store.woo_store.build_in_batch(rails_store)
      end
    end
  end
end
