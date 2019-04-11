class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create
    file_rep = FileReputationDispute.new

    customer = find_or_create_customer
    attributes = {
        sha256_hash: file_rep_params[:sha256_hash],
        file_name: file_rep_params[:file_name],
        file_size: file_rep_params[:file_size],
        sample_type: file_rep_params[:sample_type],
        disposition_suggested: file_rep_params[:disposition_suggested],
        source: file_rep_params[:source],
        platform: file_rep_params[:platform],
        status: FileReputationDispute::STATUS_NEW,
        customer: customer
    }
    file_rep.assign_attributes(attributes)
    if file_rep.save
      sender_params[:addressee_id] = file_rep.id
      sender_params[:addressee_status] = file_rep.status
      Bridge::GenericAck.new(sender_params, addressee: envelope_params[:sender]).post
      render plain: '"successfully created file rep"', status: :ok
    else
      error_messages = file_rep.errors.full_messages.join('; ')
      render plain: "\"Error(s) creating file rep -- #{error_messages}\"", status: :internal_server_error
    end
  end

  private

  def envelope_params
    params.require(:envelope).permit(:channel, :sender, :addressee)
  end

  def sender_params
    params.require(:message).require(:sender_data).permit!
  end

  def file_rep_params
    params.require(:message).require(:file_rep).permit(:sha256_hash, :file_name, :file_size, :sample_type,
                                                       :disposition_suggested, :source, :platform)
  end

  def customer_params
    params.require(:message).require(:file_rep).require(:customer).permit(:email, :name, :company_name)
  end

  def find_or_create_customer
    args = customer_params
    if customer_params['email'].present?
      Customer.find_or_create_customer(customer_email: args['email'],
                                       name: args['name'],
                                       company_name: args['company_name'])
    else
      nil
    end
  end
end
