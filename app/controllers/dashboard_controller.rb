class DashboardController < ApplicationController
  protect_from_forgery
  def index
      @store = Store.find_by(sku: ENV['STORE_SKU'])
      @run_syncronizer = RunSyncronizer.last
  end

  def show
    @store = Store.find_by(sku: params[:store_sku])
    @resource = params[:resource]
    @sorting_method = params[:sort_by] || 'sku'
    @categories = categories
    @products = products
    @product = product
  end

  def errors
    @errors =
      File.open("#{Rails.root}/log/#{Rails.env}.log").readlines.select { |x| x.include?('!!!') }
    @store = Store.find_by(sku: params[:store_sku])
    return unless @store

    # @api_products_skus = @store&.api_products&.map { |x| x['sku'] }
    # @api_to_rails_products = @store&.products&.where&.not(sku: @api_products_skus)
    @rails_to_woo_products = @store&.products&.where&.not(sku: @store&.run_syncronizers.last.woo_products_saved&.map { |x| x['sku'] })
  end

  def active_synchronizer
    ApiSynchronizer.perform_async(params[:env], params[:store])
  end

  private

  def attributes
    %i[
      name sku url_external_api url_woocommerce customer_key secret_key metadata
    ]
  end

  def categories
    case @resource
    when 'api'
      @store
      .run_syncronizers.last
      .api_products
        .map { |x| x['clasificadores'] }
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
    when 'rails'
      @store.products.map do |product|
        product.classifications.as_json(only: %i[name slug], methods: %i[subcategories])
      end
    when 'woocommerce'
      @store.woo_categories.select { |x| x['parent'].zero? }.map do |category|
        {
          'id' => category['id'],
          'name' => category['name'],
          'slug' => category['slug'],
          'products' => category['count'],
          'subcategories' => woo_subcategories(category['id'])
        }
      end
    end.flatten.uniq
  end

  def woo_subcategories(parent_id)
    @store
      .woo_categories
      .select { |x| x['parent'] == parent_id }
      .map { |x| { 'id' => x['id'], 'name' => x['name'], 'slug' => x['slug'], 'products' => x['count'] } }
  end

  def products
    case @resource
    when 'api'
      @store.run_syncronizers.last.api_products
    when 'rails'
      @store.products
    when 'woocommerce'
      @store.run_syncronizers.last.woo_products_saved
    end.sort_by { |product| product[@sorting_method].to_s }
  end

  def product
    case @resource
    when 'api'
      @store.run_syncronizers.last.api_products.find { |x| x['sku'].to_s == params[:product_sku] }
    when 'rails'
      @store.products.find_by(sku: params[:product_sku])
    when 'woocommerce'
      @store.run_syncronizers.last.woo_products_saved.find { |x| x['sku'] == params[:product_sku] }
    end
  end
end
