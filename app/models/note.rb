class Note < ApplicationRecord
  belongs_to :bug
  validates :comment, presence: true

  after_create { |note| note.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |note| note.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |note| note.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def guidance
    #DETECTION GUIDANCE:
    case
      when /^DETECTION GUIDANCE:(?<answer>.*?)^[ A-Z]+:/m =~ comment
        answer
      when /^DETECTION GUIDANCE:(?<answer>.*)\z/m =~ comment
        answer
    end
  end

  def populated?
    # when /^REFERENCES:(?<answer>.*)$/m =~ comment

  end

  def record(action)
    record = { resource: 'note',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
