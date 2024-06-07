class Bridge::SendGenericEmailEvent < Bridge::BaseMessage
  def initialize(addressee:)
    super(channel: 'generic-email-sendgrid',
          addressee: addressee)
  end

  def post(mail_params, mail_attachments = [], s3_paths = []) # TODO: remove extra logging
    Delayed::Worker.logger.error("Starting Bridge::SendGenericEmailEvent with #{mail_params}")
    super(message: {to: mail_params[:to],
                    from: mail_params[:from],
                    subject: mail_params[:subject],
                    body: mail_params[:body],
                    attachments: mail_attachments,
                    s3_paths: s3_paths
                    })
    Delayed::Worker.logger.info("Finished Bridge::SendGenericEmailEvent with #{mail_params}")
  end
  handle_asynchronously :post, :queue => "send_email"
end
