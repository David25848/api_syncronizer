# frozen_string_literal: true

# Classification model
class Classification < ApplicationRecord
  belongs_to :store
  has_many :subcategories

  validate :already_exists, on: :create

  KEYS_EXCEPTIONS = %w[id].freeze

  # def woocommerce_id
  #   woocommerce_ids.find do |hash|
  #     hash['store'] == store.sku && hash['id'].present?
  #   end&.dig('id')
  # end

  def self.create_or_update_batch_from_api(api_categories, store)
    classi_ids = []
    subcat_ids = []

    api_categories&.each do |category|
      classification = find_or_create_by!(
        slug: category['slug']&.parameterize,
        name: category['name'],
        store: store
      )

      classification.create_or_update_woocommerce_id

      classi_ids << classification.id
      next if category['subcategories'].blank?

      subcat_ids += Subcategory.upserts_by_api(classification, category['subcategories'])
    end
    { classifications_ids: classi_ids.uniq, subcategory_ids: subcat_ids.uniq }
  end

  # Find for create category in woocommerce or update category in rails
  def create_or_update_woocommerce_id(woo_category = nil)
    woo_category ||=
      store.woo_categories&.find { |x| x['slug'] == slug }

    # if already exists category in woocommerce
    if woo_category.blank?
      # Create category from parent woo_category
      data = build_create_ecommerce_data

      # Create a category in woocommerce
      woo_category = store.woo_store.create_category(data)
    end
    update!(woocommerce_id: woo_category['id'])
    # woocommerce_ids_data =
    #   woocommerce_ids
    #     .uniq { |x| x['store'] }
    # new_woocommerce_id = [{ 'store': store.sku, 'id': woo_subcategory['id'] }]
    # data =
    #   (woocommerce_ids_data|new_woocommerce_id)
    #   .reject { |x| x[:store].present? || x[:id].present? }
    # update!(woocommerce_ids: data)
    woo_category
  end

  # Correct format for create category in woocommerce
  def build_create_ecommerce_data
    {
      name: name,
      slug: slug&.parameterize
    }
  end

  private

  def already_exists
    sub_slug = Classification.find_by(slug: slug, store_id: store.id)
    sub_name = Classification.find_by(name: name, store_id: store.id)
    errors.add(:slug, 'is already taken for this store') if sub_slug
    errors.add(:name, 'is already taken for this store') if sub_name
  end
end
