class Escalations::PeakeBridge::FileRepMessagesController < ApplicationController
  # skip_before_action :require_login

  def create

    file_rep = FileReputationDispute.where(file_name: file_rep_params[:file_rep_name]).first
    file_rep ||= FileReputationDispute.new

    sandbox_score = nil
    sandbox_score_result = FileReputationApi::Sandbox.amp_lookup(file_rep_params[:sha256_checksum])
    if sandbox_score_result[:success] && sandbox_score_result[:data]["value"].present?
      sandbox_score = sandbox_score_result[:data]["value"]
    end
    attributes = {
        file_name: file_rep_params[:file_rep_name],
        sha256_hash: file_rep_params[:sha256_checksum],
        source: file_rep_params[:email],
        status: 'NEW',
        sandbox_score: sandbox_score

    file_rep = FileReputationDispute.new

    threat_score = nil
    threatgrid_private = nil
    if file_rep_params[:sha256_checksum].present?
      threatgrid_response = Threatgrid::Search.query(file_rep_params[:sha256_checksum])

      threat_score = threatgrid_response['threat_score']
      threatgrid_private = threatgrid_response['threatgrid_private']
    end


    summary = "New File Rep Dispute generated at #{DateTime.now.utc.strftime("%Y-%m-%d %H:%M")}"

    full_description = %Q{
          File name: #{file_rep_params[:file_name]};
          SHA256 hash: #{file_rep_params[:sha256_hash]}
    }

    bug_attrs = {
        'product' => 'Escalations Console',
        'component' => 'FileRep',
        'summary' => summary,
        'version' => 'unspecified',
        'description' => full_description,
        'priority' => "P3",
        'classification' => 'unclassified',
    }

    bug_proxy = bugzilla_rest_session.create_bug(bug_attrs)

    customer = find_or_create_customer
    attributes = {
        id: bug_proxy.id,
        sha256_hash: file_rep_params[:sha256_hash],
        file_name: file_rep_params[:file_name],
        file_size: file_rep_params[:file_size],
        sample_type: file_rep_params[:sample_type],
        disposition_suggested: file_rep_params[:disposition_suggested],
        source: file_rep_params[:source],
        platform: file_rep_params[:platform],
        threatgrid_score: threat_score,
        threatgrid_private: threatgrid_private,
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
    params.require(:message).require(:file_rep).fetch(:customer, {}).permit(:email, :name, :company_name)
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
