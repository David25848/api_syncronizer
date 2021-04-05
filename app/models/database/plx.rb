# frozen_string_literal: true

module Database
  # Model to connect Plx database
  class Plx < ApplicationRecord
    self.abstract_class = true

    DB_NAME = :plx

    connects_to database: { writing: DB_NAME, reading: DB_NAME }
  end
end
