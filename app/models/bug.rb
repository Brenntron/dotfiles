class Bug < ApplicationRecord

  def self.build_bugzilla_attrs(summary, full_description)

    bug_attrs = {
        'product' => 'Research',
        'component' => 'Snort Rules',
        'summary' => summary,
        'version' => 'No Version Specified', #self.version,
        'description' => full_description,
        # 'opsys' => self.os,
        'priority' => 'Unspecified',
        'classification' => 'unclassified',
        'assigned_to' => "vrt-incoming@sourcefire.com",
        'status' => "NEW"
    }

    bug_attrs

  end

  def self.build_local_research_bug_from_bugzilla_bug(research_bug_proxy)
    new_bug = Bug.new
    new_bug.id = research_bug_proxy.id
    new_bug.type = "ResearchBug"
    new_bug.summary = research_bug_proxy.summary
    new_bug.status = research_bug_proxy.status
    new_bug.resolution = research_bug_proxy.resolution
    new_bug.resolution = 'OPEN' if new_bug.resolution.blank?
    new_bug.state = 'NEW'
    new_bug.priority = research_bug_proxy.priority
    new_bug.component = research_bug_proxy.component
    new_bug.product = research_bug_proxy.product


    creator = User.user_by_email(research_bug_proxy.creator)
    new_bug.creator = creator.id unless creator.blank?

    new_user = User.user_by_email(research_bug_proxy.assigned_to)
    new_bug.user_id = new_user.id unless new_user.blank?

    new_committer = User.user_by_email(research_bug_proxy.qa_contact)
    new_bug.committer_id = new_committer.id unless new_committer.blank?

    new_bug.save


    new_bug
  end

  def self.call_thing(one, two, three:, four:)
    puts 'here'
  end

end
