class AbusiveContentTool
  #INCIDENTDATETIME FORMAT = 2012-10-15T08:00:00-07:00
  NCMEC_REPORT_TEMPLATE = <<-EOT
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
          <firstName>[SUBMITTER_FIRST_NAME]</firstName>
          <lastName>[SUBMITTER_LAST_NAME]</lastName>
          <email>[SUBMITTER_EMAIL]</email>
          <address>300 East Tasman Drive San Jose, CA 95134 USA</address>
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

    report_results = {}
    report_results[:status] = "success"
    begin
      iwf_results = self.submit_to_iwf(complaint_entry, user, url)
      report_results[:iwf] = iwf_results
    rescue Exception => e
      Rails.logger.error(e.message)
      report_results[:status] = "error"
      report_results[:iwf] = {:status => "error"}
    end

    begin
      ncmec_results = self.submit_to_ncmec(complaint_entry, user, url)
      report_results[:ncmec] = iwf_results
    rescue Exception => e
      Rails.logger.error(e.message)
      report_results[:status] = "error"
      report_results[:ncmec] = {:status => "error"}
    end

  end

  def self.submit_to_ncmec(complaint_entry, user, url)
    response = Webcat::Ncmec.call_xml_request(params)

    response_xml = Nokogiri::XML(response[:body])
    response_code = response_xml.xpath('//responseCode').text
    if response_code == "0"
      report_id = doc.xpath('//reportId').text
      AbuseRecord.build_and_save_record(response_xml, report_id, 'NCMEC', complaint_entry)
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

    AbuseRecord.build_and_save_record(response[], results[:data], 'IWF', complaint_entry)
    results


  end
end