# frozen_string_literal: true

# CimoSynchronizerJob
class CimoSynchronizerJob < ApplicationJob
  queue_as :high_priority

  def perform(env_store_sku)
    env, store_sku = env_store_sku.split(' ')
    job_log "===> Synchronizing automatically on: #{store_sku.capitalize}, #{env.capitalize} from Job at: #{Time.now}"
    database = store_sku.split('-').last.to_sym
    klass = "Database::#{database.capitalize}".constantize
    job_log "===> Connecting to database: #{database}"
    job_log "=====> Connected ActiveRecord::Base => #{ActiveRecord::Base.connection.current_database}"
    job_log "=====> Connected #{database} => #{klass.connection.current_database}"
    klass.connected_to(database: { writing: database }) do
      store = Store.find_by(sku: store_sku)
      if store
        CimoSynchronizer.sync(env, store)
      else
        Rails.logger.error "!!! ERROR: Store #{store} not found for database: #{database}"
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error "!!! ERROR: Cannot connect database: #{database}"
    Rails.logger.error "!!! ERROR: ActiveRecord database: #{ActiveRecord::Base.connection.current_database}"
    Rails.logger.error "!!! ERROR: #{e}"
  end

  private

  def job_log(info)
    Rails.logger.info("\033[32m#{info}\033[0m")
  end
end
