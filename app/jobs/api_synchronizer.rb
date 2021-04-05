# frozen_string_literal: true

require 'sidekiq-scheduler'

# Jobs for sync products data
class ApiSynchronizer
  include Sidekiq::Worker

  def perform(env, store_sku)
    CimoSynchronizerJob.perform_later("#{env} #{store_sku}")
  end
end
