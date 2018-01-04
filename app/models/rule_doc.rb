class RuleDoc < ApplicationRecord
  belongs_to :rule

  #DEFAULT LANGUAGE FOR FORM

  DEFAULT_SUMMARY_TEXT = "This event is generated when "
  DEFAULT_CONTRIBUTOR_TEXT = "Cisco's Talos Intelligence Group "

  COPY_KEYS = %w{summary impact details affected_sys attack_scenarios ease_of_attack false_positives false_negatives
                 corrective_action contributors policies is_community}



  before_create :compose_impact, if: Proc.new { |doc| doc.impact.blank? }
  before_save :check_default_text

  has_many :references, through: :rule

  delegate :sid, :gid, :new_rule?, to: :rule, allow_nil: true

  def check_default_text
    if self.summary == DEFAULT_SUMMARY_TEXT
      self.summary = ""
    end
  end

  def compose_impact
    self.impact = self.rule.rule_classification
  end

  def copy_to_rule_ids(rule_ids)
    begin
      ActiveRecord::Base.transaction do
        copy_attrs = self.attributes.slice(*COPY_KEYS)

        rule_ids.each do |curr_rule_id|
          next if curr_rule_id.to_i == self.rule_id

          curr_rule_doc = RuleDoc.where(rule_id: curr_rule_id).first
          curr_rule_doc ||= RuleDoc.new(rule_id: curr_rule_id)
          curr_rule_doc.update!(copy_attrs)
        end
      end
    rescue Exception => e
      Rails.logger.error "Docs failed to copy, backing out all changes."
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      error = "There was an error when attempting to copy a rule doc, no docs were copied."
      {:error => error}.to_json
    end


    'success'
  end


  #prepare_rule_doc_hash rule doc by translating certain information from rule to rule doc for persistence
  #right now this is all #metadata driven, so if that's empty, just stop here and return the hash
  #explicity set community to false, since the only way community can be true is if it exists in metadata
  #peel policy strings from the metadata comma-delimited list; accumulate in policies variable
  #find ruleset community? If so, now it can explicity be set to true.
  #set rule_set.policies to the accumulated policies and then return hash
  #rule_doc must be a hash at this time, in the future it will probably be able to support AR objects
  def self.prepare_rule_doc_hash(rule_doc, rule)
    policies = []
    metadata = rule.metadata

    return rule_doc if metadata.blank?
    raise "rule_doc must be a hash, not an active record object" if !rule_doc.kind_of?(Hash)

    rule_doc[:is_community] = false

    metadata.split(",").each do |token|
      if token.include?("policy")
        policies << token.gsub("policy", "").strip
      end

      if token.strip == "ruleset community"
        rule_doc[:is_community] = true
      end
    end

    rule_doc[:policies] = policies.join(", ")

    rule_doc
  end

  def self.copy_doc_action(src_rule_id, rule_ids)
    rule_doc = RuleDoc.where(rule_id: src_rule_id).first
    raise "Cannot find rule doc" unless rule_doc

    rule_doc.copy_to_rule_ids(rule_ids)
  end
end

