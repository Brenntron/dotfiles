require 'nokogiri'
class AbusiveContentTool
  #INCIDENTDATETIME FORMAT = 2012-10-15T08:00:00-07:00
  BACKUP_NCMEC_REPORT_TEMPLATE = <<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="https://report.cybertip.org/ispws/xsd">
    <incidentSummary>
        <incidentType>Child Pornography (possession, manufacture, and distribution)</incidentType>
        <incidentDateTime>[INCIDENT_TIME]</incidentDateTime>
        <escalateToHighPriority>Immediate risk to child</escalateToHighPriority>
    </incidentSummary>
    <internetDetails>
        <webPageIncident>
            <url>[MALICIOUS_URL]</url>
            <additionalInfo>TBD - potentially description of suspected csam if not obvious</additionalInfo>
            <thirdPartyHostedContent>Yes</thirdPartyHostedContent>
        </webPageIncident>
    </internetDetails>
    <reporter>
        <reportingPerson>
            <firstName>[SUBMITTER_FIRST_NAME]</firstName>
            <lastName>[SUBMITTER_LAST_NAME]</lastName>
            <email>[SUBMITTER_EMAIL]</email>
            <address>300 East Tasman Drive San Jose, CA 95134 USA</address>
        </reportingPerson>
        <contactPerson>
          <firstName>[CONTACT_FIRST_NAME]</firstName>
          <lastName>[CONTACT_LAST_NAME]</lastName>
          <email>[CONTACT_EMAIL]</email>
          <address>300 East Tasman Drive San Jose, CA 95134 USA</address>
        </contactPerson>
    </reporter>
</report>
<incidentDateTimeDescription>risk</incidentDateTimeDescription>
        <escalateToHighPriority>Immediate risk</escalateToHighPriority>
  EOT




  NCMEC_REPORT_TEMPLATE = <<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<report xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="https://report.cybertip.org/ispws/xsd">
    <incidentSummary>    
        <incidentType>Child Pornography (possession, manufacture, and distribution)</incidentType>
        <incidentDateTime>[INCIDENT_TIME]</incidentDateTime>     
    </incidentSummary>
    <internetDetails>
        <webPageIncident thirdPartyHostedContent="true">
            <url>[MALICIOUS_URL]</url>
            <additionalInfo>TBD</additionalInfo>
        </webPageIncident>
    </internetDetails>
    <reporter>
        <reportingPerson>
            <firstName>[SUBMITTER_FIRST_NAME]</firstName>
            <lastName>[SUBMITTER_LAST_NAME]</lastName>
            <email>[SUBMITTER_EMAIL]</email>
            <address>
              <address>300 East Tasman Drive</address>
              <city>San Jose</city>
              <zipCode>95134</zipCode>
              <state>CA</state>
              <country>US</country>
            </address>
        </reportingPerson>
        <contactPerson>
          <firstName>[CONTACT_FIRST_NAME]</firstName>
          <lastName>[CONTACT_LAST_NAME]</lastName>
          <email>[CONTACT_EMAIL]</email>
          <address>
              <address>300 East Tasman Drive</address>
              <city>San Jose</city>
              <zipCode>95134</zipCode>
              <state>CA</state>
              <country>US</country>
            </address>
        </contactPerson>
    </reporter>
</report>
  EOT

  REQUEST_FOR_INFO_EMAIL_BODY_TEMPLATE = <<-EOT

    <br />CSAM REPORT BREAKDOWN FOR SUBMITTED URL: [REPORT_URL]<br/>
  
    <h3>ORIGINAL COMPLAINT BREAKDOWN</h3>

    <br />
    complaint id: [REPORT_COMPLAINT_ID]<br />
    complaint entry id: [REPORT_COMPLAINT_ENTRY_ID]<br />
    complaint url: [REPORT_URL]<br />
    complaint status: [REPORT_COMPLAINT_STATUS]<br />
    complaint resolution: [REPORT_COMPLAINT_RESOLUTION]<br />
    complaint resolution message: [REPORT_COMPLAINT_MESSAGE]<br />
    complaint created on: [REPORT_COMPLAINT_CREATED]<br />
    complaint resolved on: [REPORT_COMPLAINT_RESOLVED_ON]<br />
    <br />

    <h3>IWF REPORT SUBMISSION</h3><br />
    [REPORT_IWF_SUBMISSION_FIELDS]
    <br />
    <h3>IWF RESPONSE</h3><br />
    [REPORT_IWF_RESPONSE]
    <br />
    <h3>NCMEC REPORT SUBMISSION</h3><br />
    [REPORT_NCMEC_SUBMISSION_FIELDS]
    <br />
    <h3>NCMEC RESPONSE</h3><br />
    [REPORT_NCMEC_RESPONSE]
    <br />
  EOT

  #<reportResponse>
      #<responseCode>0</responseCode>
    #<responseDescription>Success</responseDescription>
      #<reportId>4564654</reportId>
 #   <fileId>b0754af766b426f2928a02c651ed4b99</fileId>
      #  <hash>fafa5efeaf3cbe3b23b2748d13e629a1</hash>
#</reportResponse>

  def self.current_child_abuse_category
    return {:id => 64, :descr => "Child Abuse Content", :mnem => "cprn"}
    #'csam' might be the next category in the near future, look out for this new category, id 64 would be 'retired' in this scenario
    #<Wbrs::Category:0x00007fa8c624d9b8 @desc_long="Worldwide illegal child sexual abuse content.", @descr="Child Abuse Content", @is_active=1, @mnem="cprn", @category_id=64>
  end

  def self.generic_extreme_category
    return {:id => 75, :descr => "Extreme", :mnem => "extr"}
    #<Wbrs::Category:0x00007fbb43bfcc40 @desc_long="Material of a sexually violent or criminal nature; violence and violent behavior; tasteless, often gory photographs, such as autopsy photos; photos of crime scenes, crime and  accident victims; excessive obscene material; shock websites.", @descr="Extreme", @is_active=1, @mnem="extr", @category_id=75>
  end

  def self.reclassify_abuse_categories(category_ids_array)
    new_array = []
    category_ids_array.each do |id|
      if id == current_child_abuse_category[:id]
        new_id = generic_extreme_category[:id]
        new_array << new_id
      else
        new_array << id
      end
    end

    return new_array

  end

  def self.submit_abuse_to_authorities(complaint_entry, user, url, force=false)

    #do a report existence check for each before sending, as this method will be re-used by a recovery tool

    abuse_records = AbuseRecord.where(:complaint_entry_id => complaint_entry.id)
    iwf_exists = abuse_records.select {|rec| rec.source == AbuseRecord::IWF && rec.report_ident.present?}.first rescue nil
    ncmec_exists = abuse_records.select {|rec| rec.source == AbuseRecord::NCMEC && rec.report_ident.present?}.first rescue nil

    ncmec_results = nil
    iwf_results = nil

    report_results = {}
    report_results[:status] = "success"

    if (!iwf_exists.present?) || force==true
      begin
        iwf_results = self.submit_to_iwf(complaint_entry, user, url, iwf_exists)
        report_results[:iwf] = iwf_results
      rescue Exception => e
        Rails.logger.error(e.message)
        report_results[:status] = "error"
        report_results[:iwf] = {:status => "error"}
        iwf_results = nil
      end
    else
      report_results[:iwf] = {:status => "exists", :abuse_record_report_id => iwf_exists.report_ident}
    end

    if (!ncmec_exists.present?) || force==true
      begin
        ncmec_results = self.submit_to_ncmec(complaint_entry, user, url, ncmec_exists)
        report_results[:ncmec] = ncmec_results
      rescue Exception => e
        Rails.logger.error(e.message)
        report_results[:status] = "error"
        report_results[:ncmec] = {:status => "error"}
        ncmec_results = nil
      end
    else
      report_results[:ncmec] = {:status => "exists", :abuse_record_report_id => ncmec_exists.report_ident}
    end
    #needs an official notification system here but for right now email talosweb if there is an anomaly
    # in reporting results
    self.validate_report(complaint_entry, report_results)

    report_results
  end

  def self.process_email_report(complaint_entry, report_results)

    report_alert_args = {}
    if Rails.env == "production"
      report_alert_args[:to] = "admatter@cisco.com"
    else
      report_alert_args[:to] = "talosweb@cisco.com"
    end

    report_alert_args[:from] = "noreply@talosintelligence.com"
    report_alert_args[:subject] = "IWF Report Notification"

    body = "Reference Data <br /> Complaint ID: #{complaint_entry.complaint.id} <br /> Complaint Entry ID: #{complaint_entry.id} <br /> Entry: #{complaint_entry.hostlookup} <br /> User assigned: #{complaint_entry.user.cvs_username}"
    body += "<br />"
    body += "NCMEC Report ID: #{report_results[:ncmec][:abuse_record_report_id]}" rescue "Error in NCMEC reporting"
    body += "<br />"
    body += "IWF Report ID: #{report_results[:iwf][:abuse_record_report_id]}" rescue "Error in IWF reporting"
    report_alert_args[:body] = body

    attachments_to_mail = []
    conn = ::Bridge::SendGenericEmailEvent.new(addressee: 'talos-intelligence')
    conn.post(report_alert_args, attachments_to_mail)
  end

  def self.build_ncmec_body(complaint_entry, user, url)

    time = Time.now

    #`%z` gives the timezone offset as +hhmm or -hhmm.
    inc_formatted_time = time.strftime('%Y-%m-%dT%H:%M:%S')

    #convert the timezone format from +hhmm to +hh:mm
    inc_tz_offset = time.strftime('%z') # "+hhmm" or "-hhmm"
    formatted_timezone_offset = "#{inc_tz_offset[0..2]}:#{inc_tz_offset[3..4]}"

    #combine formatted time and timezone offset
    incident_time = "#{inc_formatted_time}#{formatted_timezone_offset}"


    malicious_url = url
    submitter_first_name = "Robert"
    submitter_last_name = "Frost"
    submitter_email = "rofrost@cisco.com"

    contact_first_name = "Elena"
    contact_last_name = "Garcia"
    contact_email = "ncmec_escalations@cisco.com"

    xml_body = NCMEC_REPORT_TEMPLATE.gsub('[INCIDENT_TIME]', incident_time)
                   .gsub('[MALICIOUS_URL]', malicious_url).gsub('[SUBMITTER_FIRST_NAME]', submitter_first_name)
                   .gsub('[SUBMITTER_LAST_NAME]', submitter_last_name).gsub('[SUBMITTER_EMAIL]', submitter_email)
                   .gsub('[CONTACT_FIRST_NAME]', contact_first_name).gsub('[CONTACT_LAST_NAME]', contact_last_name)
                   .gsub('[CONTACT_EMAIL]', contact_email)

    #xml_doc = Nokogiri::XML(xml_body) do |config|
    #  config.default_xml.noblanks
    #end

    #clean_xml_body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" + xml_doc.to_xml(indent: 0, save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip

    clean_xml_body = xml_body
    return clean_xml_body
  end

  def self.submit_to_ncmec(complaint_entry, user, url, abuse_record = nil)
    results = {}
    results[:status] = nil
    results[:response_code] = nil
    results[:response] = nil

    body = self.build_ncmec_body(complaint_entry, user, url)
    begin
      response = Webcat::Ncmec.call_xml_request(body, "/ispws/submit")

      response_xml = Nokogiri::XML(response.body)
      response_code = response_xml.xpath('//responseCode').text
      if response_code == "0"
        results[:status] = "success"
        report_id = response_xml.xpath('//reportId').text
        abuse_record = AbuseRecord.build_and_save_record(url, body, response_xml, report_id, AbuseRecord::NCMEC, user, complaint_entry, abuse_record)
      else
        results[:status] = "error"
        abuse_record = AbuseRecord.build_and_save_record(url, body, response_xml, nil, AbuseRecord::NCMEC, user, complaint_entry, abuse_record)
      end

      results[:response_code] = response_code
      results[:response] = response.body
      results[:abuse_record_id] = abuse_record.id
      results[:abuse_record_report_id] = abuse_record.report_ident
    rescue
      results[:status] = "error"
      abuse_record = AbuseRecord.build_and_save_record(url, body, nil, nil, AbuseRecord::NCMEC, user, complaint_entry, abuse_record)
      results[:abuse_record_id] = abuse_record.id
      results[:abuse_record_report_id] = abuse_record.report_ident
    end

    results

  end

  def self.submit_to_iwf(complaint_entry, user, url, abuse_record = nil)

    results = {}

    params = {}

    params["Reporting_Type"] = "R"
    if Rails.env == "production"
      params["Live_Report"] = "L"
    else
      params["Live_Report"] = "T" #(this will send a test report that will not affect our real data, once you are ready to go live, change this to “L".)
    end

    params["Media_Type_ID"] = 1
    params["Report_Channel_ID"] = 51
    params["Origin_ID"] = 16
    params["Submission_Type_ID"] = 19
    params["Reported_Category_ID"] =  2
    params["Reported_URL"] = url #Full URL (maximum 1000 characters)
    params["Reporter_Anonymous"] = "N"
    params["Reporter_First_Name"] = "Cisco"
    params["Reporter_Last_Name"] = "Report"
    params["Reporter_Email_ID"] = "iwf_response@cisco.com"
    params["Reporter_Organisation"] =  "Cisco"
    params["Reporter_Country_ID"] =  223
    params["Newsgroup_Name"] =  nil
    params["Newsgroup_Author"] =  nil
    params["Newsgroup_Subject"] =  nil
    params["Newsgroup_Message_ID"] =  nil
    params["Newsgroup_Date"] =  nil
    params["Newsgroup_Provider"] =  nil
    params["Reporter_Description"] =  "Generated by AC-E"
    params["Reporter_Reference"] = "de-id-#{complaint_entry.id}"  #dispute entry id, later should probably be dispute id when 1 ticket 1 entry

    #puts params.inspect
    begin
      response = Webcat::Iwf.call_json_request(params)

      if response["responseCode"].to_i == 200
        results[:status] = "success"
      else
        results[:status] = "error"
      end
      results[:message] = response["responseDescription"]
      results[:data] = response["responseData"] rescue nil

      abuse_record = AbuseRecord.build_and_save_record(url, params.to_json, response, results[:data], AbuseRecord::IWF, user, complaint_entry, abuse_record)
      results[:abuse_record_id] = abuse_record.id
      results[:abuse_record_report_id] = abuse_record.report_ident

    rescue
      results[:status] = "error"
      abuse_record = AbuseRecord.build_and_save_record(url, params.to_json, nil, nil, AbuseRecord::IWF, user, complaint_entry, abuse_record)
      results[:abuse_record_id] = abuse_record.id
      results[:abuse_record_report_id] = abuse_record.report_ident
    end

    results


  end

  def self.validate_report(complaint_entry, report_results)
    abuse_records = complaint_entry.abuse_records

    has_iwf = nil
    has_ncmec = nil

    has_iwf = abuse_records.any? {|rec| rec.report_ident.present? && rec.source == AbuseRecord::IWF }
    has_ncmec = abuse_records.any? {|rec| rec.report_ident.present? && rec.source == AbuseRecord::NCMEC }

    if [has_iwf, has_ncmec].include?(false)
      generate_email_for_notification(complaint_entry, abuse_records)
    else
      process_email_report(complaint_entry, report_results)
    end



    #check if both reports exist, if one is missing, construct report and send to talosweb
  end

  def self.generate_email_for_notification(complaint_entry, abuse_records)
    subject = "ALERT: ABUSE RECORD FAILURE FOR SDO DETECTED"

    iwf_record_id = abuse_records.select {|rec| rec.source == AbuseRecord::IWF}.first.record_ident.to_s rescue ""
    ncmec_record_id = abuse_records.select {|rec| rec.source == AbuseRecord::NCMEC}.first.record_ident.to_s rescue ""
    body = "Possible reporting failure detected.  Here is known report info breakdown:\n"
    body += "Complaint Entry ID: #{complaint_entry.id}\n" rescue ""
    body += "IWF Report ID: #{iwf_record_id}\n" rescue ""
    body += "NCMEC Report ID: #{ncmec_record_id}\n" rescue ""

    report_alert_args = {}

    report_alert_args[:from] = "noreply@talosintelligence.com"
    report_alert_args[:subject] = subject
    report_alert_args[:body] = body

    attachments_to_mail = []
    email_list = ["talosweb@cisco.com"]
    if Rails.env == "production"
      email_list << "admatter@cisco.com"
    end
    email_list.each do |email_address|
      report_alert_args[:to] = email_address
      conn = ::Bridge::SendGenericEmailEvent.new(addressee: 'talos-intelligence')
      conn.post(report_alert_args, attachments_to_mail)
    end

  end

  def self.forward_report(complaint_entry, cc)
    subject = "CSAM INCIDENT REPORT FOR A CATEGORIZED URL"
    body = self.generate_body_for_third_party(complaint_entry)
    report_alert_args = {}
    report_alert_args[:from] = "noreply@talosintelligence.com"
    report_alert_args[:subject] = subject
    report_alert_args[:body] = body

    emails_array = Rails.configuration.abuse_emails.split(",")
    emails_array += cc.split(",") unless cc.blank?
    attachments_to_mail = []
    emails_array.each do |email_address|
      report_alert_args[:to] = email_address.strip
      conn = ::Bridge::SendGenericEmailEvent.new(addressee: 'talos-intelligence')
      conn.post(report_alert_args, attachments_to_mail)
    end

  end

  def self.generate_body_for_third_party(complaint_entry)
    abuse_records = complaint_entry.abuse_records
    report_complaint_id = complaint_entry.complaint.id.to_s
    report_complaint_entry_id = complaint_entry.id.to_s
    report_url = abuse_records.first.url.to_s
    report_complaint_status = complaint_entry.status.to_s
    report_complaint_resolution = complaint_entry.resolution.to_s
    report_complaint_message = complaint_entry.resolution_comment.to_s
    report_complaint_created = complaint_entry.created_at.to_s
    report_complaint_resolved_on = complaint_entry.case_resolved_at.to_s

    report_iwf_submission_fields = ""
    report_iwf_response = ""

    report_ncmec_submission_fields = ""
    report_ncmec_response = ""

    iwf_report = abuse_records.select {|rec| rec.source == AbuseRecord::IWF}.first rescue nil
    if iwf_report.present?
      iwf_fields = JSON.parse(iwf_report.report_submitted) rescue nil
      if iwf_fields.present?
        report_iwf_submission_fields += "<br />"
        iwf_fields.each do |key, field|
          report_iwf_submission_fields += "#{key}: #{field}<br />"
        end
      end
      report_iwf_response = iwf_report.result
    end


    ncmec_report = abuse_records.select {|rec| rec.source == AbuseRecord::NCMEC}.first rescue nil
    if ncmec_report.present?
      ncmec_xml_doc = Nokogiri::XML(ncmec_report.report_submitted)
      report_ncmec_submission_fields = self.traverse_report_xml(ncmec_xml_doc.root)
      report_ncmec_response = ncmec_report.result
    end

    email_body = REQUEST_FOR_INFO_EMAIL_BODY_TEMPLATE.gsub('[REPORT_URL]', report_url).gsub('[REPORT_COMPLAINT_ID]', report_complaint_id).gsub('[REPORT_COMPLAINT_ENTRY_ID]', report_complaint_entry_id)
                     .gsub('[REPORT_COMPLAINT_STATUS]', report_complaint_status).gsub('[REPORT_COMPLAINT_RESOLUTION]', report_complaint_resolution).gsub('[REPORT_COMPLAINT_MESSAGE]', report_complaint_message)
                     .gsub('[REPORT_COMPLAINT_CREATED]', report_complaint_created).gsub('[REPORT_COMPLAINT_RESOLVED_ON]', report_complaint_resolved_on).gsub('[REPORT_IWF_SUBMISSION_FIELDS]', report_iwf_submission_fields)
                     .gsub('[REPORT_IWF_RESPONSE]', report_iwf_response).gsub('[REPORT_NCMEC_SUBMISSION_FIELDS]', report_ncmec_submission_fields).gsub('[REPORT_NCMEC_RESPONSE]', report_ncmec_response)
    email_body
  end

  def self.traverse_report_xml(xml_node)
    captured_string = ""
    xml_node.children.each do |child|
      if child.element? && child.children.size == 1 && child.children.first.text?
        captured_string += "#{child.name}: #{child.text}\n"
      else
        captured_string += traverse_report_xml(child)
      end
    end
    captured_string
  end

  def self.get_report_data(complaint_entry_id)
    report_data = {}
    report_data[:ncmec_report] = {}
    report_data[:iwf_report] = {}
    report_data[:complaint_ticket_info] = {}

    complaint_entry = ComplaintEntry.find(complaint_entry_id)

    abuse_records = complaint_entry.abuse_records

    ncmec_report = abuse_records.select {|rec| rec.source == AbuseRecord::NCMEC}.first rescue nil
    iwf_report = abuse_records.select {|rec| rec.source == AbuseRecord::IWF}.first rescue nil

    if ncmec_report.present?
      report_data[:ncmec_report][:report_ident] = ncmec_report.report_ident
      report_data[:ncmec_report][:report_submitted] = ncmec_report.report_submitted
      report_data[:ncmec_report][:result] = ncmec_report.result
      report_data[:ncmec_report][:submitter] = ncmec_report.submitter
      report_data[:ncmec_report][:created] = ncmec_report.created_at
    end

    if iwf_report.present?
      report_data[:iwf_report][:report_ident] = iwf_report.report_ident
      report_data[:iwf_report][:report_submitted] = iwf_report.report_submitted
      report_data[:iwf_report][:result] = iwf_report.result
      report_data[:iwf_report][:submitter] = iwf_report.submitter
      report_data[:iwf_report][:created] = iwf_report.created_at
    end

    assignee = User
    reviewer = User
    second_reviewer = User

    report_data[:complaint_ticket_info][:url] = complaint_entry.hostlookup
    report_data[:complaint_ticket_info][:assignee] = complaint_entry.hostlookup
    report_data[:complaint_ticket_info][:reviewer] = complaint_entry.hostlookup
    report_data[:complaint_ticket_info][:second_reviewer] = complaint_entry.hostlookup
    report_data[:complaint_ticket_info][:created] = complaint_entry.hostlookup
    report_data
  end

end