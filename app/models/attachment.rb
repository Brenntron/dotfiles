class Attachment < ApplicationRecord
  belongs_to :bug, optional: true

  has_many :alerts, dependent: :destroy
  has_many :pcap_alerts, -> { pcap_alerts }, class_name: Alert
  has_many :local_alerts, -> { local_alerts }, class_name: Alert
  has_many :exploits

  after_create { |attachment| attachment.record 'create' if Rails.configuration.websockets_enabled == 'true' }
  after_update { |attachment| attachment.record 'update' if Rails.configuration.websockets_enabled == 'true' }
  after_destroy { |attachment| attachment.record 'destroy' if Rails.configuration.websockets_enabled == 'true' }

  def record(action)
    record = { resource: 'attachment',
               action: action,
               id: self.id,
               obj: self }
    PublishWebsocket.push_changes(record)
  end

  def create_attachment
    if params[:file_upload]
      begin
        bug = Bug.find(session[:bug_id])
        attach = params[:file_upload][:attachment]

        # Move it back to the original name before attaching it
        file = File.join('tmp', attach.original_filename)
        FileUtils.mv attach.tempfile, file

        # Attach using the xmlrpc interface
        bug.add_attachment(bugzilla_session, file)

        # Remove the old file as we no longer need it
        FileUtils.rm file

        # Pull in all new attachments from bugzilla
        bug.update_attachments(Bugzilla::Bug.new(bugzilla_session))

        # Now test all the attachments
        redirect_to controller: 'tasks', action: 'wait', id: test_all(bug, filter_attachments(bug.attachments)).id

      rescue Exception => e
        log_error(e)
        redirect_to controller: 'bugs', action: 'open', id: bug.id
      end
    end
  end

  def update_attachments
    begin
      bug = Bug.find(active_scaffold_session_storage[:constraints][:bug])
      bug.update_attachments(Bugzilla::Bug.new(bugzilla_session))
      if !bug.attachments.empty?
        redirect_to controller: 'tasks', action: 'wait', id: test_all(bug, filter_attachments(bug.attachments)).id
      else
        redirect_to controller: 'bugs', action: 'open', id: bug.id
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
