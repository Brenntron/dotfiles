class Bridge::SendEmailEvent < Bridge::BaseMessage
  def initialize(addressee:, source_authority: nil, source_key: nil)
    super(channel: 'email-sendgrid',
          addressee: addressee)
  end

  def post(mail_params, attachments = [])
    super(message: {to: mail_params[:to],
                    from: mail_params[:from],
                    subject: mail_params[:subject],
                    body: mail_params[:body],
                    attachments: mail_attachments
                    })
  end
end
