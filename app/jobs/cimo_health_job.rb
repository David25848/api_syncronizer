# frozen_string_literal: true

# CimoHealthJob
class CimoHealthJob < ApplicationJob
  queue_as :high_priority

  def perform
    job_log "======> Running Cron Jobs at: #{Time.now}"
  end

  private

  def job_log(info)
    Rails.logger.info("\033[32m#{info}\033[0m")
  end
end