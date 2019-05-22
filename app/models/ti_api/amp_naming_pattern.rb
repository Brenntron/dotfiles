class TiApi::AmpNamingPattern < TiApi::Base
  attr_reader :m_amp_naming_convention, :old_position

  def initialize(m_amp_naming_convention)
    @m_amp_naming_convention = m_amp_naming_convention
    @old_position = m_amp_naming_convention.table_sequence
  end

  def update(amp_naming_convention_given = m_amp_naming_convention)
    return false unless amp_naming_convention_given.valid?
    input = {
        ticode: Rails.configuration.talos_intelligence.api_key,
        amp_naming_pattern: {
            old_position: old_position,
            new_position: amp_naming_convention_given.table_sequence,
            pattern: amp_naming_convention_given.pattern,
            example: amp_naming_convention_given.example,
            description: amp_naming_convention_given.engine_description,
            notes: amp_naming_convention_given.public_notes
        }
    }
    self.class.call_request(:put, 'api/v1/amp_naming_patterns', input: input)
    return true
  end
end
