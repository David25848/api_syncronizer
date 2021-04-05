# frozen_string_literal: true

module Database
  # Model to connect Shoelab database
  class Shoelab < ApplicationRecord
    self.abstract_class = true

    DB_NAME = :shoelab

    connects_to database: { writing: DB_NAME, reading: DB_NAME }
  end
end
