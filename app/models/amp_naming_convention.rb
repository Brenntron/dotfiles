class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine_description, :public_notes, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }

  def update_from_params(patterns)
    patterns.each do |pattern_params|
      attribute_values = pattern_params.slice(*AmpNamingConvention.column_names)
      attribute_values.delete('id')

      ti_pattern = TiApi::AmpNamingPattern.new(self) #sets the old table_sequence
      assign_attributes(attribute_values)
      raise errors.full_messages.to_sentence unless valid?
      ti_pattern.update!(self)
      save!
    end

    return true
  end
end
