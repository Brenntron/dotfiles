class Attachment < ActiveRecord::Base
  belongs_to :bug
  has_and_belongs_to_many :rules
  has_many :exploits

  def create_attachment
    if params[:file_upload]
      begin
        bug = Bug.find(session[:bug_id])
        attach = params[:file_upload][:attachment]

        # Move it back to the original name before attaching it
        file = File.join("tmp", attach.original_filename)
        FileUtils.mv attach.tempfile, file

        # Attach using the xmlrpc interface
        bug.add_attachment(bugzilla_session, file)

        # Remove the old file as we no longer need it
        FileUtils.rm file

        # Pull in all new attachments from bugzilla
        bug.update_attachments(Bugzilla::Bug.new(bugzilla_session))

        # Now test all the attachments
        redirect_to :controller => 'jobs', :action => 'wait', :id => test_all(bug, filter_attachments(bug.attachments)).id

      rescue Exception => e
        log_error(e)
        redirect_to :controller => 'bugs', :action => 'open', :id => bug.id
      end
    end
  end

  def update_attachments
    begin
      bug = Bug.find(active_scaffold_session_storage[:constraints][:bug])
      bug.update_attachments(Bugzilla::Bug.new(bugzilla_session))
      if bug.attachments.size > 0
        redirect_to :controller => 'jobs', :action => 'wait', :id => test_all(bug, filter_attachments(bug.attachments)).id
      else
        redirect_to :controller => 'bugs', :action => 'open', :id => bug.id
      end
    rescue Exception => e
      log_error(e)
      redirect_to request.referer
    end
  end

  def import_rules(bug, attachment)
    attachment.rules.each do |rule|
      begin
        bug.rules << rule
      rescue ActiveRecord::RecordNotUnique => e
        # Ignore
      end
    end

    bug.save

  end


end