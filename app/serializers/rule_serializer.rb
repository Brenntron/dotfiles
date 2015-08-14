class RuleSerializer < ActiveModel::Serializer
  attributes :id, :gid, :sid, :rev, :rule_content, :cvs_rule_content, :rule_parsed, :cvs_rule_parsed, :rule_warnings, :connection, :message, :flow, :detection, :metadata, :class_type, :average_check,:average_match,:average_nonmatch, :state, :tested, :committed, :created_at, :updated_at, :bugs, :attachments
  has_many :references, embed: :ids, embed_in_root: true
  def bugs # writing a new method because AMS doesn't have has_and_belongs_to_many
    bug_ids = []
    binding.pry
    object.bugs.each { |b| bug_ids << b.id }
    bug_ids
  end
  # has_many :attachments, embed: :ids, embed_in_root: true
  def attachments # writing a new method because AMS doesn't have has_and_belongs_to_many
    attachment_ids = []
    # binding.pry
    # Attachment.joins(:rules).merge(Rule.where(:id => object.id)).each {|a| attachment_ids << a.id}
    attachment_ids
  end
end