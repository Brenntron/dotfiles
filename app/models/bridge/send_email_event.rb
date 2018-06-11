class Bridge::SendEmailEvent < Bridge::BaseMessage
  def initialize(addressee:)
    super(channel: 'email-sendgrid',
          addressee: addressee)
  end

  def post(mail_params, mail_attachments = [])
    super(message: {to: mail_params[:to],
                    from: mail_params[:from],
                    subject: mail_params[:subject],
                    body: mail_params[:body],
                    attachments: mail_attachments
                    })
  end
end
