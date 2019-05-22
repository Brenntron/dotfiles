class AmpNamingConvention < ApplicationRecord
  validates :table_sequence, :pattern, :example, :engine_description, :public_notes, presence: true

end
