# Controller for hook called when rule has been updated in version control
#
# POST /rule_sync/rule_files?filename=rules/file-java.rules,so_rules/file-java.rules
#
# Rule files are stored (and shared) in an Apache Subversion (svn) repository.
# The svn repo has a pre-commit hook which pre-processes the rule file.
# The svn repo has a post-commit hook which calls us to notify us that the file has changed.
#
#
# The pre-process PRE hook
#
# The pre-process PRE hook validates the rules and ups the rev of the sid.
# When an `svn commit` command is run for a rules file, the PRE hook runs.
# It shells out to do the actual commit, but then always fails the commit command which was called.
# A successful preprocess run will return a 199 code, or a 0 if it was not a rule file and bypassed the hook.
#
# The shell to do the actual commit, copies the tentative commit into a local working folder (WC).
# It runs scripts to validate the rules, and then to set the sid for a new rule, and increment the rev.
# Then does a commit, but with a flag to circumvent the PRE hook.
#
#
# The notify Analyst-Console POST hook
#
# When a commit happens we get notified through a web call.
# This comes into the controller below as a create action.
#
# The pre-process PRE hook is set to fail and not do an svn commit.
# However, it shells out to a process which if validation succeeds does the actual commit.
# We get the notification from this actual commit.
module RuleSync
  class RuleFilesController < ApplicationController

    # Takes a comma separated list of file paths, to notify us to update those files from version control.
    # POST /rule_sync/rule_files?filename=rules/file-java.rules,so_rules/file-java.rules
    def create
      sync = RuleFileSync.sync(params['filenames'] || params['filename'])
      raise sync.inspect
    end
  end
end
