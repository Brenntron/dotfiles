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

  #  42 ->  xx
  # 137 -> 1xx
  # 218 -> 2xx
  def sid_group
    if 100 > sid
      'xx'
    else
      sid.to_s.sub(/\d\d$/, 'xx')
    end
  end

  def self.baseurl
    Rails.configuration.ruledocs_repo_url
  end

  def self.basepath
    @basepath ||= Pathname.new('extras/ruledocs')
  end

  def self.mk_basepath
    unless File.directory?(basepath)
      FileUtils.mkpath(basepath)
      `#{RuleFile.svn_cmd} co --depth empty #{baseurl} #{basepath}`
    end

  end

  def ruledir
    case gid
      when 1
        'snort-rules'
      when 3
        'so_rules'
      else
        "preproc_rules/gid_#{gid}"
    end
  end

  def dirpath
    self.class.basepath.join(ruledir, "sid_#{sid_group}").tap do |dirpath|
      self.class.mk_basepath
      unless File.directory?(dirpath)
        # `#{RuleFile.svn_cmd} co --depth files #{self.class.baseurl}#{ruledir}/sid_#{sid_group} #{dirpath}`
        FileUtils.mkpath(dirpath)
      end
    end
  end

  def basename
    "sid_#{sid}.ruledoc.json"
  end

  def filepath
    File.expand_path(basename, dirpath)
  end

  def affected_sys_array
    affected_sys.present? ? [affected_sys] : []
  end

  def corrective_action_array
    corrective_action.present? ? [corrective_action] : []
  end

  def contributors_array
    contributors.present? ? [contributors] : []
  end

  def reference_data_array
    references.map { |ref| ref.reference_data }
  end

  def policies_array
    policies.present? ? [policies] : []
  end

  def nested
    {
        "Summary" => summary,
        "Impact" => impact,
        "Detailed Information" => details,
        "Affected Systems" => affected_sys_array,
        "Attack Scenarios" => attack_scenarios,
        "False Positives" => false_positives,
        "False Negatives" => false_negatives,
        "Corrective Action" => corrective_action_array,
        "Contributors" => contributors_array,
        "Additional References" => reference_data_array,
        "Policies" => policies_array,
        "Community" => is_community
    }
  end

  def assign_from_json(json)
    data_collection = JSON.parse(json)
    data = data_collection[sid.to_s].first
    self.summary = data["Summary"]
    self.impact = data["Impact"]
    self.details = data["Detailed Information"]
    self.affected_sys = data["Affected Systems"].join(' ')
    self.attack_scenarios = data["Attack Scenarios"]
    self.false_positives = data["False Positives"]
    self.false_negatives = data["False Negatives"]
    self.corrective_action = data["Corrective Action"].join(' ')
    self.contributors = data["Contributors"].join(' ')
    self.policies = data["Policies"].join(' ')
    self.is_community = data["Community"]
    self
  end

  def write_to_file
    return false if new_rule?

    File.open(filepath, 'wt') do |file|
      file.puts(JSON.pretty_generate({sid => [nested]}))
    end
    true
  end

  def read_from_file
    File.open(filepath, 'rt') do |file|
      file.read
    end
  end

  def fetch_from_repo
    system("#{RuleFile.svn_cmd} up #{filepath}")
  end

  def revert_doc
    if fetch_from_repo && File.exists?(filepath)
      assign_from_json(read_from_file)
      save!
    else
      errors.add(:base, "Attempt at reverting Rule Doc for sid #{rule.sid} failed")
    end
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

