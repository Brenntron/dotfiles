module Repo
  # class RuleCommitter handles committing rule content and rule docs.
  # Calls RuleContentCommitter class to commit the rule content.
  class RuleCommitter
    include Enumerable

    class << self
      attr_reader :publish_lock_pid
    end

    attr_reader :content_committer, :rule_files, :rules, :new_rules, :changed_rules, :unchanged_rules
    attr_reader :xmlrpc, :bug, :user, :username

    def self.log(message)
      Rails.logger.info "svn integration: #{message}"
    end

    def log(message)
      self.class.log(message)
    end

    def doc_committer(rules_given)
      Repo::RuleDocCommitter.new(rules_given, username: username)
    end

    # @return [Mutex] mutex to exclusively change publishing lock
    def self.publish_mutex
      @publish_mutex ||= Mutex.new
    end

    # lock publishing, so current thread is only thread doing a commit
    def self.publish_lock
      log("publish lock")
      publish_mutex.synchronize do
        if @publish_lock_pid
          nil
        else
          @publish_lock_pid = Process.pid
          true
        end
      end
    end

    # unlock publishing, so other threads can log publishing
    # Threads other than the one which locked publishing can unlock it.
    # It is up to the developer (via writting the code) to only unlock it from the right thread.
    def self.publish_unlock
      log("publish unlock")
      publish_mutex.synchronize do
        @publish_lock_pid = nil
      end
    end

    # @return [Boolean] if publishing is currently locked by some thread
    def self.publish_locked?
      publish_mutex.synchronize do
        !@publish_lock_pid
      end
    end

    # build svn command for command line
    def self.svn_cmd
      unless @svn_cmd
        pwd_switch = Rails.configuration.svn_pwd.present? ? "--password #{Rails.configuration.svn_pwd}" : nil
        @svn_cmd = "#{Rails.configuration.svn_cmd} #{pwd_switch}"
      end
      @svn_cmd
    end

    # call svn
    # params [String] svn_args string of command line after the svn command.
    def self.call_svn(svn_args)
      log("calling svn #{svn_args}")
      output = `#{svn_cmd} #{svn_args} 2>&1`
      log('svn output: ' + output.split("\n").join(' ~')) unless output.blank?
      output
    end

    # @return [Pathname] path (possibly relative) to the snort directory synchronized with svn
    def self.synch_root
      @snort_path ||= Pathname.new('extras/snort')
    end

    # @return [Pathname] relative path name of the version control working directory to use for commits
    def self.working_root
      @svn_pathname ||= Pathname.new('extras/working')
    end

    # @param [Pathname, String] input file name, absolute or relative
    # @return [Pathname] the part of the file name relative to a working folder, the synchronized or working folder
    def self.relative_path_of(filepath)
      relative_path = Pathname.new(filepath)
      relative_path = relative_path.relative_path_from(Rails.root) if relative_path.absolute?
      relative_path = relative_path.relative_path_from(synch_root) if relative_path.to_s.starts_with?(synch_root.to_s)
      relative_path
    end

    def initialize(rules, xmlrpc:, bugzilla_id: nil, user: nil, username: nil)
      @xmlrpc = xmlrpc
      @bug = bugzilla_id ? Bug.where(bugzilla_id: bugzilla_id).first : nil
      @user = user
      @username = username || user.cvs_username
      @rules = rules
      @changed_rules, @unchanged_rules = rules.partition { |rule| rule.content_changed? }
      @new_rules = nil
      @content_committer =
          Repo::RuleContentCommitter.new(rules, bugzilla_id: bugzilla_id, user: user, username: username)
    end

    def rule_files
      content_committer.rule_files
    end

    def event_start
      @rule_commit_event = RuleEvent::RuleCommitEvent.start(bug.bugzilla_id, rules, user.id)
    end

    def event_set_result(result)
      @rule_commit_event&.update(result: result)
    end

    def event_success
      @rule_commit_event&.update(failed: false)
    end

    def event_complete
      @rule_commit_event&.update(completed: true)
    end

    # Write commit information to bugzilla
    def commit_bugzilla(bugzilla_comment: '', svn_result_output:)
      new_summary = bug.summary
      if new_rules
        new_summary = bug.update_summary_sids(new_rules, xmlrpc: self.xmlrpc)
      end
      bugzilla_commit_note = <<~NOTE
          Commit Log:
          --------------
          #{svn_result_output}
          --------------
          
          Committer Notes:
          ---------------
          #{bugzilla_comment}
          ---------------
      NOTE
      bug.state = bug.get_state("RESOLVED", "FIXED", bug.user.email)
      bug.save!
      bug_attributes = {ids: [bug.id], qa_contact: content_committer.user.email,
                        summary: new_summary,
                        status: "RESOLVED",
                        resolution: "FIXED",
                        comment: { body: bugzilla_commit_note } }
      bug.update_bugzilla_attributes(self.xmlrpc, bug_attributes)
    end

    # Rule committing code when the publish is locked
    # param [Array[Rule]] rules_given array of rules.
    # param [Repo::RuleContentCommitter] content_committer The committer object.
    def locked_commit(bugzilla_comment: '')
      if self.class.publish_lock
        event_start

        if changed_rules.any?
          log("publishing #{changed_rules.count} rules")

          #set all the rules we will update to publishing.
          Rule.set_pubcontent_state(Rule.where(id: changed_rules))

          svn_result_output = content_committer.commit_rule_content
          event_set_result(svn_result_output)
          raise "Rule content commit failed." unless content_committer.success
          if Rule.with_pub_content.exists?
            log("calling failsafe")
            rule_files.each do |rule_file|
              rule_file.synch_failsafe
            end
          end
          @new_rules = Rule.where(id: changed_rules.partition { |rule| rule.sid.nil? }.first).all.to_a

          commit_bugzilla(bugzilla_comment: bugzilla_comment, svn_result_output: svn_result_output)
        end


        # update revs and get sids of new rules
        @rules = Rule.where(id: rules).all.to_a


        log("publishing rule docs for #{rules.count} rules")
        Rule.set_pubdoc_state(Rule.where(id: content_committer.unchanged_rules))

        doc_committer(@rules).commit_docs

        event_success

        log('returning a success')
        true
      end

    ensure
      #any rules not set to synch by svn hook should go back to current.
      if Rule.with_pub_any.exists?
        log("setting rules from publishing to current_edit")
        Rule.with_pub_any.update_all(publish_status: Rule::PUBLISH_STATUS_CURRENT_EDIT)
      end

      event_complete

      log("unlocking publishing")
      self.class.publish_unlock
      log("exiting publishing")
    end

    # Handle the action from the API controller for committing rules.
    #
    # This method handles setup and cleanup around constructing the committer object and calling it.
    # Note that if it was merged with the method which does the work,
    # then there would be too much in the rescue and ensure sections.
    # That is a bad situation, because exceptions raised in the rescue and ensure sections
    # are not handled properly (or alternatively the code gets out of hand).
    #
    # param [Array[Rule]] rules array of rules.
    # param [String] username The username to add to the svn comment (message)
    # param [FixNum] bugzilla_id The bugzilla id of the bug
    # param [Boolean] nodoc_override true if commit should skip check prohibiting missing rule docs
    def self.commit_rules_action(rules, username:, bugzilla_id:, bugzilla_comment:, xmlrpc:, nodoc_override: false)
      user = User.where(cvs_username: username).first
      bug = bugzilla_id ? Bug.where(bugzilla_id: bugzilla_id).first : nil
      Repo::RuleContentCommitter.prescreen!(rules, user, bug: bug, nodoc_override: nodoc_override)


      committer = Repo::RuleCommitter.new(rules,
                                          xmlrpc: xmlrpc,
                                          bugzilla_id: bugzilla_id,
                                          user: user,
                                          username: username)
      committer.locked_commit(bugzilla_comment: bugzilla_comment).tap do

        #synch history to pick up new bugzilla commit note created by rulecommitter.
        bugzilla_bug = Bugzilla::Bug.new(xmlrpc)
        bug = bugzilla_bug.get(bugzilla_id)
        Bug.synch_history(bugzilla_bug, bug)

      end

    rescue
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      raise
    end
  end
end
