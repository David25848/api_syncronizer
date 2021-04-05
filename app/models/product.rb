# frozen_string_literal: true

# Product model
class Product < ApplicationRecord
  # For woocommerce_rest_product_invalid_id
  EXCLUDE_KEYS = %i[id type_product color
                    product_related_ids parent_id brands genders disciplines
                    variations tags links store_id metadata_attributes
                    metadata_default_attributes menu_order menu_data
                    grouped_products date_created date_modified clasificadores
                    created_at updated_at woocommerce_id].freeze

  STATUSES = %w[draft pending private publish future].freeze

  TYPES = %w[simple grouped external variable].freeze
  belongs_to :store
  has_many :categorizations
  has_many :classifications, through: :categorizations
  has_and_belongs_to_many :subcategories

  before_create :create_error_if_product_is_invalid
  before_save   :skus_without_white_space

  validate  :empty_images, :blank_variations
  validates :name, :sku, :slug, :variations, :images, presence: true
  validates :sku, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :type_product, inclusion: { in: TYPES }

  CLOTHE_SIZES_ORDER = %w[XXS XS S M L XL XXL 2XL 3XL 4XL 5XL 6XL].freeze

  def empty_images
    errors.add(:images, "Images can't be blank or empty") if images.empty?
  end

  def blank_variations
    return unless variations.blank?

    errors.add(:variations, "Variations can't be blank or empty") if variations.blank?
  end

  def product_error
    ProductError.find_by(sku: sku)
  end

  def self.define_create_and_update(products_woo)
    to_create = []
    to_update = []

    includes(:subcategories).each do |product|
      woo_product = products_woo.find { |hash| hash['sku'].to_s == product.sku }
      rails_product_in_woo = product.find_or_create_in_woocommerce(woo_product)
      if rails_product_in_woo.nil?
        to_create.push(product)
      else
        product.update(woocommerce_id: woo_product['id'])
        to_update.push(rails_product_in_woo)
      end
    end

    { to_create: to_create, to_update: to_update }
  end

  def find_or_create_in_woocommerce(woo_product)
    return if woo_product.blank?

    Rails.logger.info "PRODUCT: #{sku} INITIAL IMAGES: #{images.map { |x| x['src'].split('/').last }}"
    woo_product['images'].each do |woo_img|
      name = woo_img['name']
      dot_word = name.split('.').last
      format = ".#{dot_word}" if %w[jpg jpeg png].include?(dot_word.downcase)
      name = name.remove(format) if name.include?(format)
      dash_word = name.split('-').last
      duplicated = dash_word.to_i.positive? && dash_word.tr('0-9', '').blank?
      name = name.split('-')[0..-2].join('-') if duplicated
      img_name = "#{name}#{format}"

      images.each_with_index do |rails_img, index|
        if rails_img['src'].split('/').last.to_s == img_name
          images.delete_at(index)
          Rails.logger.info "IMG REMOVED: #{img_name} FOR: #{woo_img['name']}}"
        end
      end
    end
    Rails.logger.info "FINAL IMAGES: #{images.map { |x| x['src'].split('/').last }}"

    self
  end

  def self.build_json(to_create, to_update)
    {
      create: to_create.map(&:as_json_with_attributes),
      update: to_update.map(&:as_json_with_attributes_update)
    }
  end

  def as_json_with_attributes
    as_json(except: EXCLUDE_KEYS, methods: :categories)
      .merge(attributes: metadata_attributes,
             default_attributes: metadata_default_attributes,
             type: type_product)
  end

  def as_json_with_attributes_update
    if images.blank?
      as_json(except: [*EXCLUDE_KEYS, :images], methods: :categories)
        .merge(attributes: metadata_attributes,
              default_attributes: metadata_default_attributes,
              type: type_product,
              id: woocommerce_id)
    else
      as_json(except: EXCLUDE_KEYS, methods: :categories)
        .merge(attributes: metadata_attributes,
              default_attributes: metadata_default_attributes,
              type: type_product,
              id: woocommerce_id)
    end
  end
  
  # def woocommerce_id
  #   woocommerce_ids.find { |x| x['store'] == store.sku }['id']
  # end

  # Get categories with match in woocommerce
  def categories
    subcategories.map { |sub| { id: sub.woocommerce_id } }
  end

  # This is attributes field in woocommerce
  def metadata_attributes
    result = []

    woocommerce_attributes&.each do |name_attribute|
      result.push({ name: name_attribute,
                    position: 0,
                    visible: true,
                    variation: true,
                    options: option_attributes(name_attribute) })
    end
    result
  end

  # This is default_attributes in woocommerce
  def metadata_default_attributes
    [{
      name: woocommerce_attributes&.first,
      option: option_attributes(woocommerce_attributes&.first).first
    }]
  end

  # For get all variations types, example Talla, Color
  def woocommerce_attributes
    variations&.map { |x| x['attribute'] }&.uniq
  end

  # For get all vartiations one attribute, for example ['L', 'M'] for Talla
  def option_attributes(name_attribute)
    variations
      &.group_by { |hash| hash['attribute'] }
      &.dig(name_attribute)
      &.map { |x| x['name']&.remove(' ') }
      &.flatten
      &.sort_by { |x| CLOTHE_SIZES_ORDER.index(x).to_s }
      &.sort_by { |x| x.to_f }
      &.map { |x| x.to_s }
  end

  # Build json variations valid to wocommerce
  def build_json_variations
    result = []
    variations&.each do |variation|
      result.push(
        {
          sale_price: variation['sale_price'],
          regular_price: variation['regular_price'],
          sku: variation['sku'],
          on_sale: true,
          status: 'publish',
          purchasable: true,
          stock_quantity: variation['stock_quantity'],
          manage_stock: true,
          stock_status: 'instock',
          attributes: [
            {
              name: variation['attribute'],
              option: variation['name']
            }
          ]
        }
      )
    end
    result
  end

  def skus_without_white_space
    self.sku = sku.strip 
  end

  private

  def create_error_if_product_is_invalid
    ProductError.find_or_create_by_sku(self) if invalid?
  end
end
