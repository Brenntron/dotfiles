class Note < ApplicationRecord
  belongs_to :bug
  validates :comment, presence: true

  TEMPLATE_RESEARCH =
      "THESIS:\r\n\r\nRESEARCH:\r\n\r\nDETECTION GUIDANCE:\r\n\r\nDETECTION BREAKDOWN:\r\n\r\nREFERENCES:\r\n"

  scope :committer_note, -> { where(note_type: 'committer') }
  scope :unpublished, -> { where(notes_bugzilla_id: nil) }
  scope :published, -> {where.not(notes_bugzilla_id: nil) }
  scope :scratch_pad, -> {where(note_type: 'scratchpad')}
  scope :reverse_chron, -> {
    order("created_at desc")
  }
  scope :last_committer_note, -> { committer_note.reverse_chron.limit(1) }

  after_create { |note| note.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |note| note.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |note| note.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = {resource: 'note',
              action: action,
              id: self.id,
              obj: self}
    PublishWebsocket.push_changes(record)
  end

  def self.parse_from_note(text, delimiter, include_delimiter = false)
    new_note_block = ""
    line_started = 0
    started = false

    text.each_line.with_index do |line, i|
      if line.include?(delimiter)
        started = true
        line_started = i
      end
      if started
        if (line_started == i || line.starts_with?("------")) && !include_delimiter
          if i > (line_started + 1)
            started = false
          end
          next
        end

        line_to_add = line.blank? ? line : line.lstrip
        new_note_block += line_to_add

      end

    end
    unless include_delimiter
      new_note_block.gsub!(delimiter, "")
    end

    new_note_block

  end

  def self.process_note(options,bugzilla_session)
    new_note = Bugzilla::Bug.new(bugzilla_session).add_comment(options)
    if options[:note_id].blank?
      note = Note.create(id: new_note['id'],
                         comment: options[:comment],
                         author: options[:author],
                         note_type: options[:note_type])
    else
      note = Note.where("id=?", options[:note_id]).first
    end
    bug = Bug.find options[:id]
    bug.notes << note
    if note.update(:id => new_note['id'], :comment => options[:comment], :notes_bugzilla_id => new_note['id'])
      return true
    else
      raise "Published to bugzilla but not updated in local db"
    end
  end

end
