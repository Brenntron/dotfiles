class RuleCategory < ApplicationRecord
  has_many :rules

  validates :category, uniqueness: true

  scope :ranked, ->{ left_joins(:rules).group(:id).order('count(rules.id) desc, category') }

  def filename(gid = 1)
    # Rule.joins(:rule_category).select('rules.id, rules.gid, rules.filename, rule_categories.category').each do |rule|
    #   unless /^extras\/snort\/(?<dir>\w+)\/(?<basename>[-a-z]+)\.rules$/ =~ rule.filename
    #     puts "!!!1 rule #{rule.id} filename not in directory: '#{rule.filename}'"
    #   end
    #
    #   unless basename == rule.category.downcase
    #     unless %w[preprocessor decoder].include?(basename)
    #       puts "!!!2 rule #{rule.id} gid = #{rule.gid} file basename = '#{basename}', category = '#{rule.category.downcase}'"
    #     end
    #   end
    #
    #   case
    #     when (1 == rule.gid) && ('rules' == dir)
    #     when (3 == rule.gid) && ('so_rules' == dir)
    #     when ('preproc_rules' == dir)
    #     else
    #       puts "!!!3 cannot determine dir gid = #{rule.gid} dir = #{dir}"
    #   end
    # end; nil

    case gid
      when 1
        "extras/snort/rules/#{category.downcase}.rules"
      when 3
        "extras/snort/so_rules/#{category.downcase}.rules"
      else
        "extras/snort/preproc_rules/#{category.downcase}.rules"
    end
  end
end
