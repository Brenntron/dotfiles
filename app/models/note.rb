class Note < ApplicationRecord
  belongs_to :bug
  validates :comment, presence: true

  TEMPLATE_RESEARCH =
      "THESIS:\r\n\r\nRESEARCH:\r\n\r\nDETECTION GUIDANCE:\r\n\r\nDETECTION BREAKDOWN:\r\n\r\nREFERENCES:\r\n"

  scope :unpublished, -> { where(notes_bugzilla_id: nil) }
  scope :reverse_chron, -> {
    order("created_at desc")
  }

  after_create { |note| note.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |note| note.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |note| note.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = { resource: 'note',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end
end
