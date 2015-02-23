class NoteSerializer < ActiveModel::Serializer
  attributes :id, :content, :author, :type
end
