# frozen_string_literal: true

module Database
  # Model to connect Gosports database
  class Gosports < ApplicationRecord
    self.abstract_class = true

    DB_NAME = :gosports

    connects_to database: { writing: DB_NAME, reading: DB_NAME }
  end
end
