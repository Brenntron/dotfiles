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
            <additionalInfo>TBD - potentially description of suspected csam if not obvious</additionalInfo>
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

  def self.submit_abuse_to_authorities(complaint_entry, user, url)

    #do a report existence check for each before sending, as this method will be re-used by a recovery tool

    abuse_records = AbuseRecord.where(:complaint_entry_id => complaint_entry.id)
    iwf_exists = abuse_records.select {|rec| rec.source == AbuseRecord::IWF && rec.report_ident.present?}.present?
    ncmec_exists = abuse_records.select {|rec| rec.source == AbuseRecord::NCMEC && rec.report_ident.present?}.present?

    ncmec_results = nil
    iwf_results = nil

    report_results = {}
    report_results[:status] = "success"

    if !iwf_exists
      begin
        iwf_results = self.submit_to_iwf(complaint_entry, user, url)
        report_results[:iwf] = iwf_results
      rescue Exception => e
        Rails.logger.error(e.message)
        report_results[:status] = "error"
        report_results[:iwf] = {:status => "error"}
        iwf_results = nil
      end
    end

    if !ncmec_exists
      begin
        ncmec_results = self.submit_to_ncmec(complaint_entry, user, url)
        report_results[:ncmec] = ncmec_results
      rescue Exception => e
        Rails.logger.error(e.message)
        report_results[:status] = "error"
        report_results[:ncmec] = {:status => "error"}
        ncmec_results = nil
      end
    end
    self.process_email_report(ncmec_results, iwf_results)

  end

  def self.process_email_report(ncmec_results, iwf_results)
    abusive_info = {}
    abusive_info[:iwf_report_id] = "IWF report submission ID: #{result[:data]}"
    self.abuse_information = abusive_info.to_json
    self.save!
    report_alert_args = {}
    report_alert_args[:to] = "admatter@cisco.com"
    report_alert_args[:from] = "noreply@talosintelligence.com"
    report_alert_args[:subject] = "IWF Report Notification"
    report_alert_args[:body] = "Reference Data <br /> Complaint ID: #{self.complaint.id} <br /> Complaint Entry ID: #{self.id} <br /> Entry: #{self.hostlookup} <br /> User assigned: #{self.user.cvs_username}"

    attachments_to_mail = []
    conn = ::Bridge::SendEmailEvent.new(addressee: 'talos-intelligence')
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

  def self.submit_to_ncmec(complaint_entry, user, url)
    body = self.build_ncmec_body(complaint_entry, user, url)
    response = Webcat::Ncmec.call_xml_request(body, "/ispws/submit")

    response_xml = Nokogiri::XML(response.body)
    response_code = response_xml.xpath('//responseCode').text
    if response_code == "0"
      report_id = doc.xpath('//reportId').text
      AbuseRecord.build_and_save_record(body, response_xml, report_id, AbuseRecord::NCMEC, user, complaint_entry)
    end

  end

  def self.submit_to_iwf(complaint_entry, user, url)

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

    response = Webcat::Iwf.call_json_request(params)

    if response["responseCode"].to_i == 200
      results[:status] = "success"
    else
      results[:status] = "error"
    end
    results[:message] = response["responseDescription"]
    results[:data] = response["responseData"]

    AbuseRecord.build_and_save_record(params, response, results[:data], AbuseRecord::IWF, complaint_entry, user)
    results


  end

  def self.validate_report(complaint_entry)



    #check if both reports exist, if one is missing, construct report and send to talosweb
  end
end