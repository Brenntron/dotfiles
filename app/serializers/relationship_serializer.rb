class RelationshipSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :team_member_id
end
