class NoteSerializer < ActiveModel::Serializer
  attributes :id, :content, :author, :note_type, :bug_id, :created_at, :updated_at
end
