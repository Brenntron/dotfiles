class AmpNamingConvention < ApplicationRecord
  validates :pattern, :example, :engine_description, :public_notes, presence: true
  validates :table_sequence, presence: true, numericality: { only_integer: true }


  def self.save_batch(records)
    # Since table_sequence might be reordered, but must be unique at all times,
    # move to negative of its intended position, then negate it again.
    records.each do |record|
      record.table_sequence = -record.table_sequence
      record.save!
    end
    records.each do |record|
      record.table_sequence = -record.table_sequence
      record.save!
    end
  end
end
