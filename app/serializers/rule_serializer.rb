class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :rule_content, :rule_parsed, :rule_warnings, :rule_failures,
             :connection, :message, :flow, :detection, :metadata, :class_type,
             :state, :edit_status, :parsed, :on, :tested, :committed, :created_at, :updated_at,
             :bugs
  has_many :references, embed: :ids, embed_in_root: true
  def bugs # writing a new method because AMS doesn't have has_and_belongs_to_many
    bug_ids = []
    object.bugs.each { |b| bug_ids << b.id }
    bug_ids
  end
end
