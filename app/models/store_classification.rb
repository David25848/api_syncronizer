class StoreClassification < ApplicationRecord
  belongs_to :store
  belongs_to :classification

  validate :uniq_store_and_classification

  def uniq_store_and_classification
    exists = StoreClassification.find_by(store_id: store_id, classification_id: classification_id)
    return unless exists
    errors.add(:base, 'this association is already created')
  end
end
