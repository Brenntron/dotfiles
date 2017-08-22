class BugsRule < ApplicationRecord
  belongs_to :bug
  belongs_to :rule

  # Pre-commit hook intercepted commit, failed it, and successfully checked in the rule
  SVN_SUCCESS_COMMIT_HOOK = 199

  def svn_success?
    SVN_SUCCESS_COMMIT_HOOK == self.svn_result_code
  end
end
