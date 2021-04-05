class WebhookController < ApiController
  def created_orders
    return unless params[:status].eql?('completed')

    bill_products = products_params.to_enum.to_h

    # Returns 201 Created if everything is ok
    res = HTTParty.post("#{store_host}/ords/pedidos_web2/datos/fact", bill_products)

    headers = JSON.parse(res.headers['response'])
    response_errors = JSON.parse(res.response.to_json)

    Rails.logger.info '==================================================='
    Rails.logger.info "WEBHOOK HEADERS: #{headers}"
    Rails.logger.info "RESPONSE ERRORS: #{response_errors}"
    Rails.logger.info '=================================================='

    if res.code == 201
      render json: headers, status: 201
    else
      render json: response_errors, status: 422
    end
  end

  def health_test
    json_response = {
      status: 'healthy',
      stores: Store.all,
      products: Product.all,
      categories: Classification.all
    }
    render json: json_response, status: :ok
  end

  private

  def store_host
    case params[:store]
    when 'tiendas-plx'
      'http://168.181.162.73'
    end
  end

  # Only allow a trusted parameter "white list" through.
  def products_params
    params.require(:webhook).permit(
      :store, :webhook,
      :id, :number, :order_key, :created_via, :status, :currency,
      :discount_total, :discount_tax, :shipping_total, :shipping_tax,
      :cart_tax, :total, :total_tax, :prices_include_tax,
      :payment_method, :payment_method_title, :transaction_id, :currency_symbol,

      billing: [
        :first_name, :last_name, :company, :address_1, :address_2, :city,
        :state, :postcode, :country, :email, :phone
      ],
      shipping: [
        :first_name, :last_name, :company, :address_1, :address_2, :city,
        :state, :postcode, :country
      ],
      meta_data: [
        :id, :key, :value
      ],
      line_items: [
        :id, :name, :product_id, :variation_id, :quantity, :tax_class,
        :subtotal, :subtotal_tax, :total, :total_tax, :sku, :price,
        {
          taxes: [],
          meta_data: [:id, :key, :value]
        }
      ],
      tax_lines: [],
      shipping_lines: [
        :id, :method_title, :method_id, :instance_id, :total, :total_tax,
        {
          taxes: [],
          meta_data: [:id, :key, :value]
        }
      ],
      fee_lines: [],
      coupon_lines: [],
      refunds: [],
      webhook: [],
      taxes: []
    )
  end
end
