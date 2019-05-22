class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine_description, :public_notes, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }

end
