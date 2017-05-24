class RuleCategory < ApplicationRecord
  has_many :rules

  CATEGORY_DELETED                      = 'DELETED'
  CATEGORY_FILE_IDENTIFY                = 'FILE-IDENTIFY'

  validates :category, uniqueness: true

  scope :ranked, ->{ left_joins(:rules).group(:id).order('count(rules.id) desc, category') }

  def deleted?
    CATEGORY_DELETED == self.category
  end

  def file_identiy?
    CATEGORY_FILE_IDENTIFY == self.category
  end

  def requires_doc?
    (!deleted?) && (!file_identiy?)
  end

  def filename(gid = 1)
    case gid
      when 1
        "snort-rules/#{category.downcase}.rules"
      when 3
        "so_rules/#{category.downcase}.rules"
      else
        "preproc_rules/#{category.downcase}.rules"
    end
  end
end
