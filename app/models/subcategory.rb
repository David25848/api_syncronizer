# frozen_string_literal: true

# Subcategory model
class Subcategory < ApplicationRecord
  has_and_belongs_to_many :products
  belongs_to :classification
  delegate :store, to: :classification

  validate :already_exists, on: :create

  KEYS_EXCEPTIONS = %w[id].freeze

  # def woocommerce_id
  #   woocommerce_ids.find do |hash|
  #     hash['store'] == store&.sku && hash['id'].present?
  #   end&.dig('id')
  # end

  # Create batch subctegories by Cimo API
  def self.upserts_by_api(classification, api_subcategories)
    subcategory_ids = []
    api_subcategories.map do |api_subcategory|
      api_subcategory_data =
        api_subcategory
        .merge!(classification_id: classification.id)
        .except!(*KEYS_EXCEPTIONS)
      subcategory =
        find_by(
          slug: api_subcategory_data['slug'],
          classification_id: classification.id
        )
      if subcategory
        subcategory.update(api_subcategory_data)
      else
        subcategory = create!(api_subcategory_data)
      end
      subcategory_ids.push(subcategory.id)
    end
    subcategory_ids
  end

  # Find for create subcategory in woocommerce
  def create_in_woocommerce
    # Create a subcategory in woocommerce
    woo_subcategory = store.woo_store.create_category(build_create_ecommerce_data)
    update!(woocommerce_id: woo_subcategory['id'])
    # woocommerce_ids_data =
    #   woocommerce_ids
    #     .uniq { |x| x['store'] }
    #     .find { |x| x['store'] == store.sku }
    #     .merge!(id: woo_subcategory['id'])
    # update!(woocommerce_ids: woocommerce_ids_data)
  end

  # Find for update subcategory in Rails
  def update_by_woocommerce(woo_subcategory)
    # if already exists subcategory in woocommerce
    Rails.logger.info "=====> Found Subcategory #{name} in WooCommerce"

    Rails.logger.info "=====> Subcategory ID Rails(#{woocommerce_id}) == WooCommerce(#{woo_subcategory['id']})"
    # Update ID in Rails
    if woocommerce_id.to_s != woo_subcategory['id'].to_s
      Rails.logger.info 'NEED TO CHANGE'
      # woocommerce_ids_data =
      #   woocommerce_ids
      #     .uniq { |x| x['store'] }
      # new_woocommerce_id = [{ 'store': store.sku, 'id': woo_subcategory['id'] }]
      # data =
      #   (woocommerce_ids_data|new_woocommerce_id)
      #   .reject { |x| x[:store].present? || x[:id].present? }
      # update!(woocommerce_ids: data)
      update!(woocommerce_id: woo_subcategory['id'])
      if woocommerce_id.to_s == woo_subcategory['id'].to_s
        Rails.logger.info ">>>> Updated subcategory #{name} ID: #{woocommerce_id}\n"
      else
        Rails.logger.error "!!! ERROR: Cannot update subcategory #{name} slug: #{slug} from WooCommerce in #{store&.sku}\n"
      end
    end

    Rails.logger.info "=====> Subcategory ClassificationID(#{classification.woocommerce_id}) == WooParent(#{woo_subcategory['parent']})"
    # Update WooSubcategory Parent by Rails subcategory.classification_id
    return if woo_subcategory['parent'].to_s == classification.woocommerce_id.to_s

    woo_store = WooCommerce::API.new(*store.data_to_woocommerce)
    data = { parent: classification.woocommerce_id }
    woo_store.post("products/categories#{woo_subcategory['id']}", data).parsed_response
    return if woo_subcategory['parent'].to_s == classification.woocommerce_id.to_s

    Rails.logger.info ">>>> Updated subcategory #{name} ParentID: #{woo_subcategory['parent']}\n"
  end

  # Correct format for create category in woocommerce
  def build_create_ecommerce_data
    {
      name: name,
      slug: slug&.parameterize,
      parent: classification&.woocommerce_id
    }
  end

  private

  def already_exists
    sub_slug = Subcategory.find_by(slug: slug, classification_id: classification.id)
    sub_name = Subcategory.find_by(name: name, classification_id: classification.id)
    errors.add(:slug, 'is already taken for this classification') if sub_slug
    errors.add(:name, 'is already taken for this classification') if sub_name
  end
end
