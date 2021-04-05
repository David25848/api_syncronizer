# frozen_string_literal: true

# sku     :string
# api     :text
# woo     :text
# puclic  :boolean

# Manage product erors in API y Woo
class ProductError < ApplicationRecord
  default_scope { where(public: true) }

  def product
    Product.find_by(sku: sku)
  end

  def self.find_or_create_by_sku(product_data)
    error = find_or_create_by(sku: product_data['sku'])
    if error.product
      error.update(woo: product_data['message'])
    else
      error.update(api: product_data.errors.messages)
    end
  end
end
