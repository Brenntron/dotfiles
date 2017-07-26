class BugsRule < ApplicationRecord
  belongs_to :bug
  belongs_to :rule

  def svn_success?
    199 == self.svn_result_code
  end
end
