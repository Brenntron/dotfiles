class AbusiveContentTool

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

    results = {}

    params = {}

    params["Reporting_Type"] = "R"
    if Rails.env == "production"
      params["Live_Report"] = "L" #(this will send a test report that will not affect our real data, once you are ready to go live, change this to “L".)
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

    results

  end

end