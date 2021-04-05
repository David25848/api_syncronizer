# frozen_string_literal: true

require 'sidekiq-scheduler'

# Jobs for update products stock
class StockUpdater
  include Sidekiq::Worker

  def perform
    return unless Rails.env.production?

    update_stock_url =
      ENV['UPDATE_STOCK_URL'] ||
      case ENV['STORE_SKU']
      when 'tiendas-plx' then 'http://tiendasplx.com/stock_upd/ejecutar_plx.php'
      when 'gosports' then 'http://tiendasplx.com/stock_upd/ejecutar_pls.php'
      when 'shoelab' then 'http://tiendasplx.com/stock_upd/ejecutar_sl.php'
      end

    Rails.logger.info "===> Updating stock on: #{ENV['STORE_SKU']} to #{update_stock_url} in #{Rails.env} from Job at: #{Time.now}"
    response = HTTParty.get(update_stock_url)
    response.body.split('<br>').each do |line|
      Rails.logger.info(line)
    end
  rescue ArgumentError => e
    Rails.logger.error "!!! Error updating stock: #{e}"
  end
end
