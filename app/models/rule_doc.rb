class RuleDoc < ApplicationRecord
  belongs_to :rule

  before_create :compose_impact, if: Proc.new { |doc| doc.impact.blank? }

  has_many :references, through: :rule

  delegate :sid, :gid, :new_rule?, to: :rule, allow_nil: true

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
    'https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/'
  end

  def self.basepath
    @basepath ||= Pathname.new('extras/rulesdocs')
  end

  def self.mk_basepath
    unless File.directory?(basepath)
      FileUtils.mkpath(basepath)
      `svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/ #{basepath}`
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
    affected_sys.present? ? [ affected_sys ] : []
  end

  def corrective_action_array
    corrective_action.present? ? [ corrective_action ] : []
  end

  def reference_data_array
    references.map{|ref| ref.reference_data}
  end

  def contributors_array
    contributors.present? ? [ contributors ] : []
  end

  def nested
    {
        "Summary:" => summary,
        "Impact:" => impact,
        "Detailed Information:" => details,
        "Affected Systems:" => affected_sys_array,
        "Attack Scenarios:" => attack_scenarios,
        "False Positives:" => false_positives,
        "False Negatives:" => false_negatives,
        "Corrective Action:" => corrective_action_array,
        "Contributors:" => contributors_array,
        "Additional References:" => reference_data_array,
    }
  end

  def write_to_file
    return false if new_rule?

    File.open(filepath, 'wt') do |file|
      file.puts(JSON.pretty_generate( {sid => [ nested ]}) )
    end
    true
  end

  def call_commit(username = '')
    `svn add --force #{self.class.basepath}`
    `svn ci #{self.class.basepath} -m "#{username} committed from Analyst Console"`
  end

  def commit_doc(username = '')
    if write_to_file
      call_commit(username)
    end
  end
end

