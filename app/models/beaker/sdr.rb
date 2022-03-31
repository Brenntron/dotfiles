# Domain Reputation

require 'service-sdr_services_pb'


class Beaker::Sdr < Beaker::BeakerBase
  # Request a reputation verdict based on sender information in the SMTP
  # envelope.
  # rpc :EnvelopeQuery, ::Talos::SDR::EnvelopeRequest, ::Talos::SDR::EnvelopeReply
  # params:
  # ip - (string)
  # smtp_envelope_params
  #   * mail_from - (string)
  #   * rcpt_to - (array[string])
  #   * auth - (bool)
  #   * spf_results
  #     * helo - 'none', 'neutral', 'pass', 'fail', 'softfail', 'temperror', 'permerror', or 'notimplemented'
  #     * mail_from - 'none', 'neutral', 'pass', 'fail', 'softfail', 'temperror', 'permerror', or 'notimplemented'
  #     * dmarc_align - (bool)
  #   * helo or ehlo - (string)
  def self.envelope_query(ip, smtp_envelope_params)
    spf_results = Talos::SPFResults.new(helo: spf_result_enum(smtp_envelope_params[:spf_results][:helo]),
                                        mail_from: spf_result_enum(smtp_envelope_params[:spf_results][:mail_from]),
                                        dmarc_align: smtp_envelope_params[:spf_results][:dmarc_align])

    smtp_envelope = Talos::SMTPEnvelope.new(mail_from: smtp_envelope_params[:mail_from],
                                            rcpt_to: smtp_envelope_params[:rcpt_to],
                                            auth: smtp_envelope_params[:auth],
                                            spf_results: spf_results)

    if smtp_envelope_params[:helo].present?
      smtp_envelope.helo = smtp_envelope_params[:helo]
    elsif smtp_envelope_params[:ehlo].present?
      smtp_envelope.ehlo = smtp_envelope_params[:ehlo]
    end

    envelope_request = Talos::SDR::EnvelopeRequest.new(app_info: get_app_info,
                                                       endpoint: get_ip_endpoint(ip),
                                                       smtp_envelope: smtp_envelope,
                                                       connection: get_connection([SecureRandom.uuid.gsub("-", "")].pack("H*")),
                                                       msg_guid: [SecureRandom.uuid.gsub("-", "")].pack("H*"))

    envelope_reply = remote_stub.envelope_query(envelope_request)
  end

  # Request a reputation verdict based on sending domains.
  # rpc :DataQuery, ::Talos::SDR::DataRequest, ::Talos::SDR::DataReply
  # ip - (string)
  # esa_mid - (int)
  # smtp_envelope_params
  #   * mail_from - (string)
  #   * rcpt_to - (array[string])
  #   * auth - (bool)
  #   * spf_result_params
  #     * helo - 'none', 'neutral', 'pass', 'fail', 'softfail', 'temperror', 'permerror', or 'notimplemented'
  #     * mail_from - 'none', 'neutral', 'pass', 'fail', 'softfail', 'temperror', 'permerror', or 'notimplemented'
  #     * dmarc_align - (bool)
  #   * helo or ehlo - (string)
  # mail_data_params
  #   * from_hdr - (array[hash])
  #     * addr - (string)
  #     * display - (string)
  #   * to_hdr - (array[hash])
  #     * addr - (string)
  #     * display - (string)
  #   * reply_to_hdr - (array[hash])
  #     * addr - (string)
  #     * display - (string)
  #   * email_list - (hash)
  #     * help - (string)
  #     * unsubscribe - (string)
  #     * subscribe - (string)
  #     * post - (string)
  #     * owner - (string)
  #     * archive - (string)
  #     * unsub_post - 'valid', 'invalid', or 'none'
  #   * dkim_disabled - (bool)
  #   * dkim_disp - (hash)
  #     * domain - (string)
  #     * selector - (string)
  #     * head_canon - 'relaxed' or 'strict'
  #     * body_canon - 'relaxed' or 'strict'
  #     * dmarc_align - (bool)
  #     * uses_from_hdr - (bool)
  #     * dkim_sig_is_valid - (bool)
  #   * dmarc_disabled - (bool)
  #   * dmarc_disp - (hash)
  #     * record - (string)
  #     * strict - (bool)
  #     * aligned - (bool)
  #   * misc_hdrs - (array[hash])
  #     * name - (string)
  #     * value - (string)
  def self.data_query(ip, esa_mid, smtp_envelope_params, mail_data_params)
    spf_results = Talos::SPFResults.new(helo: spf_result_enum(smtp_envelope_params[:spf_results][:helo]),
                                        mail_from: spf_result_enum(smtp_envelope_params[:spf_results][:mail_from]),
                                        dmarc_align: smtp_envelope_params[:spf_results][:dmarc_align])

    smtp_envelope = Talos::SMTPEnvelope.new(mail_from: smtp_envelope_params[:mail_from],
                                            rcpt_to: smtp_envelope_params[:rcpt_to],
                                            auth: smtp_envelope_params[:auth],
                                            spf_results: spf_results)

    if smtp_envelope_params[:helo].present?
      smtp_envelope.helo = smtp_envelope_params[:helo]
    elsif smtp_envelope_params[:ehlo].present?
      smtp_envelope.ehlo = smtp_envelope_params[:ehlo]
    end

    email_list = Talos::EmailList.new(help: mail_data_params[:email_list][:help],
                                      unsubscribe: mail_data_params[:email_list][:unsubscribe],
                                      subscribe: mail_data_params[:email_list][:subscribe],
                                      post: mail_data_params[:email_list][:post],
                                      owner: mail_data_params[:email_list][:owner],
                                      archive: mail_data_params[:email_list][:archive],
                                      unsub_post: unsub_post_enum(mail_data_params[:email_list][:unsub_post]))

    dkim_disposition = Talos::DKIMDisposition.new(domain: mail_data_params[:dkim_disp][:domain],
                                                  selector: mail_data_params[:dkim_disp][:selector],
                                                  head_canon: dkim_canon_enum(mail_data_params[:dkim_disp][:head_canon]),
                                                  body_canon: dkim_canon_enum(mail_data_params[:dkim_disp][:body_canon]),
                                                  dmarc_align: mail_data_params[:dkim_disp][:dmarc_align],
                                                  uses_from_hdr: mail_data_params[:dkim_disp][:uses_from_hdr],
                                                  dkim_sig_is_valid: mail_data_params[:dkim_disp][:dkim_sig_is_valid])

    dmarc_disposition = Talos::DMARCDisposition.new(record: mail_data_params[:dmarc_disp][:record],
                                                    strict: mail_data_params[:dmarc_disp][:strict],
                                                    aligned: mail_data_params[:dmarc_disp][:aligned])

    mail_data = Talos::MailData.new(from_hdr: mail_data_params[:from_hdr].map {|m| Talos::EmailMailbox.new(addr: m[:addr], display: m[:display])},
                                    to_hdr: mail_data_params[:to_hdr].map {|m| Talos::EmailMailbox.new(addr: m[:addr], display: m[:display])},
                                    reply_to_hdr: mail_data_params[:reply_to_hdr].map {|m| Talos::EmailMailbox.new(addr: m[:addr], display: m[:display])},
                                    list: email_list,
                                    dkim_disabled: mail_data_params[:dkim_disabled],
                                    dkim_disp: dkim_disposition,
                                    dmarc_disabled: mail_data_params[:dmarc_disabled],
                                    dmarc_disp: dmarc_disposition,
                                    misc_hdrs: mail_data_params[:misc_hdrs].map {|m| Talos::EmailHeader.new(name: m[:name], value: m[:value])})

    data_request = Talos::SDR::DataRequest.new(app_info: get_app_info,
                                               endpoint: get_ip_endpoint(ip),
                                               smtp_envelope: smtp_envelope,
                                               mail_data: mail_data,
                                               esa_mid: esa_mid,
                                               connection: get_connection([SecureRandom.uuid.gsub("-", "")].pack("H*")),
                                               msg_guid: [SecureRandom.uuid.gsub("-", "")].pack("H*"))

    data_reply = remote_stub.data_query(data_request)
  end

  # Request a mapping of threat category IDs to mnemonics and descriptions.
  # rpc :QueryThreatCatMap, ::Talos::SDR::ThreatCatMapRequest, ::Talos::ThreatCategoryMap
  def self.query_threat_cat_map
    threat_category_map = remote_stub.query_threat_cat_map(Talos::SDR::ThreatCatMapRequest.new)
  end

  # rpc :QueryThreatLevelMap, ::Talos::SDR::ThreatLevelMapRequest, ::Talos::ThreatLevelMap
  def self.query_threat_level_map
    threat_level_map = remote_stub.query_threat_level_map(Talos::SDR::ThreatLevelMapRequest.new)
  end

  private

  def self.spf_result_enum(spf_result)
    case spf_result
    when "none"
      Talos::SPFResults::ResultType::SPF_RESULT_NONE
    when "neutral"
      Talos::SPFResults::ResultType::SPF_RESULT_NEUTRAL
    when "pass"
      Talos::SPFResults::ResultType::SPF_RESULT_PASS
    when "fail"
      Talos::SPFResults::ResultType::SPF_RESULT_FAIL
    when "softfail"
      Talos::SPFResults::ResultType::SPF_RESULT_SOFTFAIL
    when "temperror"
      Talos::SPFResults::ResultType::SPF_RESULT_TEMPERROR
    when "permerror"
      Talos::SPFResults::ResultType::SPF_RESULT_PERMERROR
    else
      Talos::SPFResults::ResultType::SPF_RESULT_NOT_IMPLEMENTED
    end
  end

  def self.unsub_post_enum(unsub_post)
    case unsub_post
    when "valid"
      Talos::EmailList::EmailListUnsubPost::EMAIL_LISTUNSUBPOST_VALID
    when "invalid"
      Talos::EmailList::EmailListUnsubPost::EMAIL_LISTUNSUBPOST_INVALID
    else
      Talos::EmailList::EmailListUnsubPost::EMAIL_LISTUNSUBPOST_NONE
    end
  end

  def self.dkim_canon_enum(dkim_canon)
    case dkim_canon
    when "relaxed"
      Talos::DKIMDisposition::DKIMCanon::DKIM_CANON_RELAXED
    when "strict"
      Talos::DKIMDisposition::DKIMCanon::DKIM_CANON_STRICT
    else
      nil
    end
  end

  def self.remote_stub
    @remote_stub ||= Talos::Service::SDR::Stub.new(hostport, creds)
  end
end
