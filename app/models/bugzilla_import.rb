class BugzillaImport

  def import(current_user, xmlrpc, xmlrpc_token, new_bugs, progress_bar = nil, import_type = "import")
    byebug
    raise 'Bug creation not converted'

    import_type = import_type.blank? ? "import" : import_type
    total_bugs = []
    unless new_bugs['bugs'].empty?
      new_bugs['bugs'].each do |item|

        progress_bar.update_attribute("progress", 10) unless progress_bar.blank?

        bug_id = item['id']



        new_attachments = xmlrpc.attachments(ids: [bug_id])

        begin
          new_comments = xmlrpc.comments(ids: [bug_id])
        rescue RuntimeError => e
          new_comments = []
          Note.create(author: 'AC Admin',
                      comment: "Sorry! The Bugzilla API can't even these comments.\nERROR: #{e}.",
                      note_type: 'error',
                      bug_id: bug_id)
        end


        #Update Bug record attributes from bugzilla############
        bug = Bug.find_or_create_by(bugzilla_id: bug_id)

        bug.initialize_report

        bug.id = bug_id
        bug.summary        = item['summary']
        bug.classification = 'unclassified'
        bug.status     = item['status']
        bug.resolution = item['resolution']
        bug.resolution = 'OPEN' if bug.resolution.empty?

        new_bug_state = bug.get_state(item['status'], item['resolution'], item['assigned_to'])
        state_changed = bug.state != new_bug_state

        bug.state     = new_bug_state if state_changed
        bug.priority  = item['priority']
        bug.component = item['component']
        bug.product   = item['product']
        bug.whiteboard = item['whiteboard']
        bug.created_at = item['creation_time'].to_time
        if state_changed
          last_change_time      = item['last_change_time'].to_time
          if bug.state == 'NEW'
            # do nothing
          elsif bug.state == 'ASSIGNED'
            bug.assigned_at = last_change_time
          elsif bug.state == 'PENDING'
            bug.pending_at = last_change_time
          elsif bug.state == 'REOPENED'
            bug.reopened_at = last_change_time
          else
            bug.resolved_at = last_change_time
          end
        end


        if import_type != "status"
          bug.save
        end
        #end Bug attributes update##################


        #Create/update Bug User relationships
        creator = User.where('email=?', item['creator']).first
        new_user = User.where('email=?', item['assigned_to']).first
        new_committer = User.where('email=?', item['qa_contact']).first

        if creator.nil?
          User.create_by_email(item['creator'])
          new_creator = User.where(email: item['creator']).first
          bug.creator = new_creator.id
        else
          bug.creator = creator.id
        end
        if new_user.nil?
          User.create_by_email(item['assigned_to'])
          new_generated_user = User.where(email: item['assigned_to']).first
          bug.user = new_generated_user
        else
          bug.user = new_user
        end
        if new_committer.nil?

          test_user = User.create_by_email(item['qa_contact'])

          new_generated_committer = User.where(email: item['qa_contact']).first
          new_generated_committer.roles << Role.where(role:"committer")
          bug.committer = new_generated_committer
        else
          bug.committer = new_committer
        end
        if import_type != "status"
          bug.save
        end


        #Create/update Bug Attachments
        unless new_attachments.empty?

          new_attachments['bugs'][bug_id.to_s].each do |attachment|
            local_attachment = Attachment.where(bugzilla_attachment_id: attachment['id']).first
            if local_attachment.present?
              if attachment['is_obsolete'] == 1
                local_attachment.is_obsolete = true
                local_attachment.save
              end
            else
              local_attachment = Attachment.create do |new_attach_record|
                new_attach_record.id = attachment['id']
                new_attach_record.size = attachment['size']
                new_attach_record.bugzilla_attachment_id = attachment['id'] #this is the id comming from bugzilla
                new_attach_record.file_name = attachment['file_name']
                new_attach_record.summary = attachment['summary']
                new_attach_record.content_type = attachment['content_type']
                new_attach_record.direct_upload_url = "https://#{Rails.configuration.bugzilla_host}/attachment.cgi?id=" + new_attach_record.id = attachment['id'].to_s
                new_attach_record.creator = attachment['attacher']
                new_attach_record.is_private = attachment['is_private']
                new_attach_record.is_obsolete = attachment['is_obsolete']
                new_attach_record.minor_update = false
                new_attach_record.created_at = attachment['creation_time'].to_time
              end
            end
            bug.import_report[:new_attachments] << attachment['file_name'] unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            if import_type != "status"
              bug.attachments << local_attachment unless bug.attachments.pluck(:bugzilla_attachment_id).include?(local_attachment.bugzilla_attachment_id)
            end
          end
        end

        ####we need to test these new attachments #unless its a status check
        #if import_type != "status"
        #  options = {
        #      :bug              => Bug.where(id: bug_id).first,
        #      :task_type        => Task::TASK_TYPE_PCAP_TEST,
        #      :attachment_array => bug.attachments.pcap.map{|a| a.id},
        #  }

        #  begin
        #    if options[:attachment_array].any?
        #      new_task = Task.create(
        #          :bug  => options[:bug],
        #          :task_type     => options[:task_type],
        #          :user => current_user
        #      )

        #      TestAttachment.new(new_task, xmlrpc_token, options[:attachment_array]).send_work_msg

        #    end
        #  rescue Exception => e
            #handle timeouts accordingly
        #    Rails.logger.info("Rails encountered an error but is moving through it. #{e.message}")
        #  end
        #end
        ####end attachment testing###


        bug_has_published_notes = bug.has_published_notes?
        bug_has_notes = bug.has_notes?

        ###build any comments/notes (research and commit messages) from bugzilla####
        ###prepolate running notes (for the Notes tab)
        bug.research_notes ||= Note::TEMPLATE_RESEARCH
        unless new_comments.empty?

          ActiveRecord::Base.transaction do
            #import any new comments from bugzilla
            new_comments['bugs'].each do |comment|
              bug_id = comment[0].to_i
              comment[1]['comments'].each do |c|
                if c['text'].downcase.strip.start_with?('commit')
                  note_type = 'committer'
                elsif c['text'].start_with?('Created attachment')
                  note_type = 'attachment'
                else
                  note_type = 'research'
                end
                comment = c['text'].strip

                creation_time = c['creation_time'].to_time

                note = Note.where(id: c['id']).first

                if note.present?
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    note.update_attributes(author: c['author'],
                                           comment: comment,
                                           bug_id: bug_id,
                                           note_type: note_type,
                                           notes_bugzilla_id: c['id'],
                                           created_at: creation_time)
                  end
                else
                  bug.import_report[:new_notes] += 1
                  unless import_type == "status"
                    comment = "bugzilla comment is blank" if comment.blank?
                    Note.create(id: c['id'],
                                author: c['author'],
                                comment: comment,
                                bug_id: bug_id,
                                note_type: note_type,
                                created_at: creation_time,
                                notes_bugzilla_id: c['id']                     )
                  end
                end
              end
            end
            #end comment importing####

            ##Running note prepoluation logic here#########
            if import_type != "status"

              #prepopulating committer notes in notes tab

              unless bug_has_published_notes
                last_committer_note = bug.notes.last_committer_note.first
                if last_committer_note.present?
                  committer_note_text_area = ""
                  if last_committer_note
                    committer_note_text_area = Note.parse_from_note(last_committer_note.comment,"Committer Notes:", true) + "\n"
                  end
                  new_note = Note.where(notes_bugzilla_id: nil,bug_id: bug_id).committer_note.first_or_create
                  new_note.note_type = 'committer'
                  new_note.comment = new_note.comment.nil? ? committer_note_text_area : committer_note_text_area + "\n" + new_note.comment
                  new_note.author = last_committer_note.nil? ? current_user.email : last_committer_note.author
                  new_note.created_at = Time.now.to_time
                  new_note.save
                end
              end

              #prepopulating research notes in notes tab
              latest_research = bug.notes.where("note_type=? and comment like 'Research Notes:%'", "research").reverse_chron.first
              if latest_research.present? && !(bug_has_notes)
                new_draft = Note.parse_from_note(latest_research.comment, "Research Notes:", false)
                bug.research_notes = new_draft
              end
            end

          end
        end
        progress_bar.update_attribute("progress", 20) unless progress_bar.blank?
        bug.load_whiteboard_values
        progress_bar.update_attribute("progress", 30) unless progress_bar.blank?
        parsed = bug.parse_summary
        progress_bar.update_attribute("progress", 50) unless progress_bar.blank?
        bug.load_rules_from_sids(parsed[:sids], bug.component, import_type)
        progress_bar.update_attribute("progress", 60) unless progress_bar.blank?
        bug.load_tags_from_summary(parsed[:tags], import_type)

        progress_bar.update_attribute("progress", 75) unless progress_bar.blank?
        bug.load_refs_from_summary(parsed[:refs], import_type)

        progress_bar.update_attribute("progress", 90) unless progress_bar.blank?

        #save the bug unless the import action is a status check
        if import_type != "status"
          bug.save
        end

        progress_bar.update_attribute("progress", 100) unless progress_bar.blank?

        total_bugs << bug

      end
    else
      if new_bugs.has_key?("faults") && !new_bugs["faults"].empty?
        message = new_bugs["faults"].map {|f| f['faultString']}.join(',')
        raise message
      else
        raise "there was a problem importing from Bugzilla."
      end
    end
    return total_bugs


  end

end