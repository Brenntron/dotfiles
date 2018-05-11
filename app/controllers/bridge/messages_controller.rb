class Bridge::MessagesController < ApplicationController
  def fp_create

    sender = envelope_params[:sender]
    Rails.logger.debug("Analyst Console recieved message, on channel fp_create from sender #{sender.inspect}")

    false_positive = FalsePositive.create_from_params(false_positive_params,
                                                      attachments_attrs: attachments_params,
                                                      sender: sender)


    Thread.new { false_positive.create_bug_action(bugzilla_session, sender) }

    render plain: "fp_create id: #{false_positive.id}", status: :ok

  rescue => except
    log_exception(except)
    render plain: except.message, status: :internal_server_error
  end

  # Message to recieve notification from subversion when a rules file has been committed.
  def rule_file_notify
    snort_dir = Rails.root.join('extras', 'snort')

    filenames = message_params.fetch(:filenames, [])
    unless filenames
      Rails.warn("No files names in notify message.")
      return "No files given to process."
    end

    relative_filenames = filenames.map do |filepath_given|
      if /(?<filename>[-\w]+\/[-\w]+\.rules)\s*$/ =~ filepath_given
        filename
      else
        Rails.logger.error("Will not process #{filename.inspect}, skipping.")
        nil
      end
    end.compact

    Thread.new do
      Rails.logger.info("svn up #{relative_filenames.join(" ")}")
      # Rails.logger.debug "cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}"
      `cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}`
      Rails.logger.info("notify svn up is done")
    end

    # Thread.new do
    #   # Rails.logger.info("svn up #{relative_filenames.join(" ")}")
    #   # # Rails.logger.debug "cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}"
    #   # `cd #{snort_dir}\\;svn up #{relative_filenames.join(' ')}`
    #   # Rails.logger.info("notify svn up is done")
    #   Repo::RuleContentCommitter.svn_up(relative_filenames)
    # end

    Repo::RuleContentCommitter.repo_notify_filenames(relative_filenames)

    "success"
  end

  # Add route for specific channels to their own action under the channels collection.
  # When there is no route, it defaults to the create action.
  def create
    channel = params[:channel_id]
    message = "Analyst Console recieved unknown (unrouted) message, on channel #{channel.inspect}"

    Rails.logger.warn(message)

    render plain: message,
           status: :internal_server_error
  end

  private

  # @return [Bugzilla::XMLRPC] Authenticated bugzilla session
  def bugzilla_session
    begin
      unless @bugzilla_session
        bugzilla_proxy = Bugzilla::XMLRPC.new(Rails.configuration.bugzilla_host)
        bugzilla_proxy.bugzilla_login(Bugzilla::User.new(bugzilla_proxy),
                                      Rails.configuration.bugzilla_username,
                                      Rails.configuration.bugzilla_password)
        @bugzilla_session = bugzilla_proxy
      end
    rescue => except
      Rails.logger.error(except.message)
    end
    @bugzilla_session
  end

  def log_exception(except)
    Rails.logger.error(except.message)
    except.backtrace[0..5].each {|line| Rails.logger.error(line)}
  end

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

  def message_params
    params.require(:message)
  end

  def false_positive_params
    message_params.require(:false_positive)
        .permit(:user_email, :sid, :description, :source_key, :os, :version, :built_from, :pcap_lib, :cmd_line_options)
  end

  def attachments_params
    # params.require(:message).require(:false_positive).require(:attachments)
    message_params.require(:false_positive)['attachments']
  end
end
