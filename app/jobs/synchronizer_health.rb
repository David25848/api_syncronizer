# frozen_string_literal: true

require 'sidekiq-scheduler'

# Jobs for sync products data
class SynchronizerHealth
  include Sidekiq::Worker

  def perform
    CimoHealthJob.perform_later
  end
end
