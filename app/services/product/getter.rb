# frozen_string_literal: true

# Getter class for obtain each value one item to product instance
class Product::Getter
  attr_reader :item, :product, :store
  KEYS_EXCEPTIONS = %w[id dimensions categories brands genders disciplines
                       variations tags images attributes clasificadores
                       default_attributes links type].freeze

  def initialize(item, store)
    @item = item
    @store = store
    find_or_initialize_object
    set_classification
    set_variations
    set_images
  end

  private

  def find_or_initialize_object
    @product = Product.find_or_initialize_by(sku: @item['sku'])
    @product.attributes = @item.except(*KEYS_EXCEPTIONS)
    @product.store      = @store
  end

  def set_classification
    Rails.logger.info "Product #{@item['sku']} loading categories: #{@item['clasificadores']}"
    if @item['clasificadores']&.blank?
      Rails.logger.error "!!! ERROR: Cannot load categories for product: #{@item['sku']} in #{@store&.sku}"
    else
      categories_batch =
        Classification.create_or_update_batch_from_api(@item['clasificadores'], @store)
      @product.classification_ids = categories_batch[:classifications_ids]
      @product.subcategory_ids = categories_batch[:subcategory_ids]
    end
  end

  def set_variations
    @product.variations = @item['variations']
  end

  def set_images
    if @item['images'].present?
      item_images = @item['images'].map { |img| { 'src' => img['SRC'] } }

      @product.images = item_images.sort_by { |image| image['src'] }
    else
      @product.errors.add(:images, 'can\'t be blank')
      ProductError.find_or_create_by_sku(@product)
      @product.destroy
    end
  end
end
