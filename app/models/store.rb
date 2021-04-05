# frozen_string_literal: true

# Store model
class Store < ApplicationRecord
  has_many :products
  has_many :run_syncronizers
  has_many :classifications

  validates :name, :url_external_api,
            :sku, uniqueness: true, presence: true
  validates :metadata, :secret_key, :customer_key, :url_woocommerce, presence: true

  def self.initialize_for(store)
    found_store = find_by(sku: store[:sku])&.update(data_to_save(store))
    create(data_to_save(store)) unless found_store
  end

  def self.data_to_save(store)
    {
      name: store[:name],
      url_woocommerce: store[:url_woocommerce],
      url_external_api: store[:url_external_api],
      sku: store[:sku],
      customer_key: store[:customer_key],
      secret_key: store[:secret_key],
      metadata: store[:metadata]
    }
  end

  def subcategories_by_products
    products.includes(:subcategories).map(&:subcategories).flatten.uniq.sort
  end

  def classifications_by_products
    products.includes(:classifications).map(&:classifications).flatten.uniq.sort
  end

  def data_to_woocommerce
    [
      url_woocommerce,
      customer_key,
      secret_key,
      metadata.symbolize_keys
    ]
  end

  def api_products
    HTTParty.get(url_external_api)['items']
  end

  def woo_store
    WooCommerce::API.new(*data_to_woocommerce)
  end

  def woo_products
    @woo_products = []
    page = 1

    loop do
      products = 
        woo_store.get('products', page: page, per_page: 100).parsed_response
      puts "Getting #{products.size} products from page #{page}"
      @woo_products += products
      page += 1
      break if products.blank? || products.size < 100
    end

    @woo_products
  end

  def woo_categories
    woo_store.categories
  end

  def self.report
    all.each do |store|
      puts "\n # #{store.name}"
      puts "Productos en API: #{store.api_products.size}"
      puts "Productos en Sync: #{store.products.size}"
      puts "Products en WooCommerce: #{store.woo_products.size}"
    end
  end

  def self.delete_all_in_rails(force: true)
    return unless force

    Rails.application.eager_load!

    exception_models = [
      Store,
      ApplicationRecord,
      ActionText::RichText,
      ActionMailbox::InboundEmail,
      ActiveStorage::Blob,
      ActiveStorage::Attachment
    ]

    klasses = ActiveRecord::Base.descendants - exception_models

    klasses.map do |klass|
      klass.delete_all
      Rails.logger.info ">>> Deleted ALL from #{klass} model"
    end
  end

  def delete_all_in_woocommerce(force: false)
    return unless force

    Rails.logger.info "\n=== Deleting all in WooCommerce from #{name}"

    woo_categories.each do |woo_category|
      response =
        begin
          woo_store.delete("products/categories/#{woo_category['id']}", force: true).parsed_response
        rescue Net::OpenTimeout
          Rails.logger.error "!!! ERROR: Cannot delete #{woo_category&.dig('slug')}. This is taking too much..."
        end
      Rails.logger.info ">>> Deleted category #{woo_category&.dig('slug')} in #{name}" if response
    end

    woo_products.each do |woo_product|
      response =
        begin
          woo_store.delete("products/#{woo_product['id']}", force: true).parsed_response
        rescue Net::OpenTimeout
          Rails.logger.error "!!! ERROR: Cannot delete #{woo_product&.dig('sku')}. This is taking too much..."
        end
      Rails.logger.info ">>> Deleted product #{woo_product&.dig('sku')}" if response
    end
  end

  def group_api_categories_by_slug
    run_syncronizers
      .last
      .api_products.map { |x| x['clasificadores'] }
      .flatten
      .compact
      .group_by { |x| x['slug'] }
      .map do |slug, api_categories|
        {
          'slug' => slug,
          'name' => api_categories.first['name'],
          'subcategories' => api_categories.map { |x| x['subcategories'] }.flatten.map { |x| x['name'] }.flatten.uniq
        }
      end
  end

  def parent_woo_categories
    woo_categories.select { |x| x['parent'].zero? }.map do |category|
      {
        'id' => category['id'],
        'name' => category['name'],
        'slug' => category['slug'],
        'products' => category['count']
      }
    end
  end
  
end
