module API
  module V1
    module Escalations
      module Webcat
        class ComplaintEntries < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaint_entries" do

            before do
              PaperTrail.request.whodunnit = current_user.id if current_user.present?
            end


            desc 'update an entry'
            params do
              requires :id, type: Integer, desc:'complaint entry id'
              optional :prefix, type: String, desc: 'the url to categorize'
              optional :categories, type: String, desc: 'a list of categories to assign to this prefix'
              optional :category_names, type: String, desc: 'a list of category names to assign to Complaint Entry record'
              optional :status, type: String, desc: 'setting the status of the entry'
              optional :comment, type: String, desc: 'internal comment'
              optional :resolution_comment, type: String, desc: 'resolution comment for the customer'
              optional :uri_as_categorized, type: String, desc: 'Value of the `Edit Uri` box at the time analyst submitted it'
            end
            post 'update'do
              std_api_v2 do

              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                uri_as_categorized = permitted_params['uri_as_categorized'].blank? ? entry.uri : permitted_params['uri_as_categorized']
                entry.change_category( permitted_params['prefix'],
                                       permitted_params['categories'],
                                       permitted_params['category_names'],
                                       permitted_params['status'],
                                       permitted_params['comment'],
                                       permitted_params['resolution_comment'],
                                       uri_as_categorized,
                                       current_user, "")

                Thread.new { ComplaintEntryPreload.generate_preload_from_complaint_entry(entry) }
                if entry.complaint.ticket_source != Complaint::SOURCE_RULEUI
                  message = Bridge::ComplaintUpdateStatusEvent.new
                  message.post_complaint(entry.complaint)
                end

              rescue Exception => e
                  return {error:e.message}.to_json
              end
              {display_name: current_user.display_name, status: entry.status, entry_resolution: permitted_params['status'],
               uri: entry.uri, domain: entry.domain, subdomain: entry.subdomain, path: entry.path, categories: params[:categories]}.to_json
              end
            end

            desc 'Bulk update entry resolutions'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
              requires :resolution_name, type: String
            end
            post 'bulk_update_entry_resolution' do
              begin
                permitted_params['complaint_entry_ids'].each do |id|
                  ComplaintEntry.update(id, :resolution => params[:resolution_name], :status => ComplaintEntry::STATUS_COMPLETED)
                end
              rescue Exception => e
                Rails.logger.error "Failed to take entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              params[:complaint_entry_ids].to_json
            end


            desc 'update high telemetry complaint entries'
            params do
              requires :data, type: Array, desc: ''
            end
            post 'update_pending' do
              begin
                params[:data].each do |submitted_complaint|
                  @entry = ComplaintEntry.find(submitted_complaint[:id])
                  @entry.change_category( submitted_complaint[:prefix],
                                          submitted_complaint[:categories],
                                          submitted_complaint[:category_names],
                                          submitted_complaint[:status],
                                          submitted_complaint[:comment],
                                          submitted_complaint[:resolution_comment],
                                          '',
                                          current_user, submitted_complaint[:commit])

                  if submitted_complaint[:commit] == 'decline'
                    category_data = @entry.current_category_data.to_a

                    if category_data.present?
                      categories = []

                      for i in 0..5 do
                        if category_data[i].present?
                          categories << category_data[i][1][:descr]
                        end
                      end

                      categories_string = categories.join(',')
                      # 1. If the pending ticket was declined, reassign it to the declining user
                      # 2. If the pending ticket had currently existing categories and was declined, set the ticket's categories to its WBRS categories
                      @entry.update(url_primary_category: categories_string, user_id: current_user.id)
                    else
                      # 3. If the pending ticket had no currently existing categories and was declined, just reassign it to the declining user
                      @entry.update(user_id: current_user.id)
                    end
                  end

                  if @entry.complaint.ticket_source != Complaint::SOURCE_RULEUI
                    message = Bridge::ComplaintUpdateStatusEvent.new
                    message.post_complaint(@entry.complaint)
                  end
                end
                response = {entry_id: @entry.id, domain: @entry.domain, subdomain: @entry.subdomain, path: @entry.path,
                            categories: @entry.url_primary_category, uri: @entry.uri, status:@entry.status,
                            entry_resolution: params[:data][0]['commit'], was_dismissed: @entry.was_dismissed?}
                response.to_json

              rescue Exception => e
                Rails.logger.error(e)
                Rails.logger.error e.backtrace.join("\n")
                e.to_json
              end
            end


            desc 'take entry'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
            end
            post 'take_entry' do
              begin
                error_entry_ids = {}
                error_count = 0
                permitted_params['complaint_entry_ids'].each do |id|
                  status = ComplaintEntry.find(id).take_complaint(current_user)
                  if status != "Complaint taken"
                    error_count += 1
                    if error_entry_ids[status].nil?
                      error_entry_ids[status] = [id]
                    else
                      error_entry_ids[status] << id
                    end
                  end
                end
                unless error_entry_ids.keys.empty?
                  if error_count == permitted_params['complaint_entry_ids'].count
                    error_message = ["The following entries could not be taken:"]
                  else
                    error_message = ["Some entries were successfully taken, but the following entries could not be taken:"]
                  end
                  error_entry_ids.keys.each do |key|
                    error_message << "#{key} - #{error_entry_ids[key].to_sentence}"
                  end
                  unless error_count == permitted_params['complaint_entry_ids'].count
                    error_message << "Refresh the page to pickup the latest changes."
                  end
                  return {:error => error_message}.to_json
                end
              rescue Exception => e
                Rails.logger.error "Failed to take entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              {name:current_user.display_name}.to_json
            end


            desc 'return entry'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
            end
            post 'return_entry' do
              begin
                error_entry_ids = {}
                error_count = 0
                permitted_params['complaint_entry_ids'].each do |id|
                  status = ComplaintEntry.find(id).return_complaint(current_user)
                  if status != "Complaint returned"
                    error_count += 1
                    if error_entry_ids[status].nil?
                      error_entry_ids[status] = [id]
                    else
                      error_entry_ids[status] << id
                    end
                  end
                end
                unless error_entry_ids.keys.empty?
                  if error_count == permitted_params['complaint_entry_ids'].count
                    error_message = ["The following entries could not be returned:"]
                  else
                    error_message = ["Some entries were successfully returned, but the following entries could not be returned:"]
                  end
                  error_entry_ids.keys.each do |key|
                    error_message << "#{key} - #{error_entry_ids[key].to_sentence}"
                  end
                  unless error_count == permitted_params['complaint_entry_ids'].count
                    error_message << "Refresh the page to pickup the latest changes."
                  end
                  return {:error => error_message}.to_json
                end
              rescue Exception => e
                Rails.logger.error "Failed to take entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              {name:current_user.display_name}.to_json

            end



            desc 'Get the history'
            params do
              requires :id, type: Integer, desc: 'ComplaintEntry id'
            end
            post 'history' do
              begin
                  entry = ComplaintEntry.find(params[:id])
                  complaint_entry_packet={}
                  complaint_entry_packet[:entry_history] = {}
                  #if entry.complaint_entry_preload.present?
                  #  if entry.complaint_entry_preload.historic_category_information.present?
                  #    complaint_entry_packet[:entry_history][:domain_history] = entry.complaint_entry_preload.historic_category_information
                  #  else
                  #    complaint_entry_packet[:entry_history][:domain_history] = entry.historic_category_data
                  #  end
                  #else
                  #  complaint_entry_packet[:entry_history][:domain_history] = entry.historic_category_data
                  #end

                  complaint_entry_packet[:entry_history][:domain_history] = entry.historic_category_data

                  complaint_entry_packet[:entry_history][:complaint_history] = entry.compose_versions



              rescue Exception => e
                Rails.logger.error "Failed to find entry: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end
              complaint_entry_packet.to_json
            end

            desc 'Get the history from Categorize URLs'
            params do
              requires :position, type: Integer, desc: "Parse URL's and retrieve history"
              requires :url, type:  String, desc: "Parse URL's and retrieve history"
            end
            post 'categorize_urls_history' do
              std_api_v2 do
                begin

                  url = Complaint.parse_url(permitted_params['url'])

                  prefix_history = []
                  prefixes = Wbrs::Prefix.where(:urls => [url[:domain]])

                  prefixes.each do |prefix|
                    if prefix.subdomain == (url[:subdomain] || '') && prefix.path == url[:path]
                      prefix_id = prefix.prefix_id

                      prefix_history = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| DateTime.parse(history.time)}.reverse
                    end
                  end
                  if prefix_history.empty?
                    raise "The URL you provided does not have available data."
                  end
                  render prefix_history.to_json
                rescue
                  raise 'The URL you provided does not have available data.'
                end
              end
            end

            desc 'get the lookup info about a url(rule)'
            params do
              requires :id, type: Integer, desc: "the id of the complaint entry"
            end
            post 'lookup' do
              std_api_v2 do
                complaint_entry = ComplaintEntry.find(permitted_params[:id])
                complaint_entry_packet = {"prefix"=>complaint_entry.domain||complaint_entry.ip_address}
                if complaint_entry.complaint_entry_preload.present?
                  if complaint_entry.complaint_entry_preload.current_category_information.present? &&
                      complaint_entry.complaint_entry_preload.current_category_information != 'DATA ERROR'
                    complaint_entry_packet[:current_categories] = {}
                    parsed_current_cat_information = JSON.parse(complaint_entry.complaint_entry_preload.current_category_information)


                    parsed_current_cat_information.each_pair do |key,value|

                      complaint_entry_packet[:current_categories][key] = {}
                      complaint_entry_packet[:current_categories][key][:certainty] = {}

                      complaint_entry_packet[:current_categories][key] = {:is_active => value['is_active'],
                                                                          :mnemonic => value['mnemonic'],
                                                                          :category_id => value['category_id'],
                                                                          :prefix_id => value['prefix_id'],
                                                                          :confidence => value['confidence'] || 'N/A',
                                                                          :name => value['name'] || 'N/A',
                                                                          :long_description => value['long_description']}
                      #TODO: replace this with working code when the API is finished and we can actually get certainty.
                      complaint_entry_packet[:current_categories][key][:certainty] = [
                          {:source => "Missing Source data", :source_category => "Missing Category", :source_certainty => "N/A", :source_confidence => 'N.A'}
                                                                                      ]
                    end


                    # complaint_entry_packet[:current_categories] = complaint_entry.complaint_entry_preload.current_category_information
                  else
                    complaint_entry_packet[:current_categories] = {}
                  end
                else
                  complaint_entry_packet[:current_categories] = {}
                end
                # find the lookup info for the url
                complaint_entry_packet.to_json
              end
            end



            desc 'look up who is information from the domain given a complaint entry id'
            params do
              requires :lookup, type: String, desc: 'ComplaintEntry ids'
            end
            post 'domain_whois' do
              whois = {}
              begin
                if /\A[\d\.]*\z/ !~ params[:lookup]
                  tld = params[:lookup].split('.').last
                  Whois::Server.define(:tld, tld, "whois.iana.org")
                end
                record = Whois.whois(params[:lookup])
                parser = Whois::Parser.new(record)
                parser.record.content.each_line do |line|
                  key,value = line.split(":",2)
                  if value&.strip == nil
                    next
                  end
                  key = key.gsub(">>>","").gsub("   ","").downcase.gsub(" ","_").to_sym
                  value = value.gsub("<<<","").gsub("   ","")&.strip
                  if whois[key]
                    if whois[key].kind_of?(Array)
                      whois[key] << value
                    else
                      whois[key] = [whois[key], value]
                    end
                  else
                    whois[key] = value
                  end
                end
              rescue Exception => e
                Rails.logger.error "Failed to determine Whois info: error=> #{e.message}"
                error = "#{e.message}"
                return {:error => error}.to_json
              end

              whois.to_json
            end


            get ':complaint_entry_id/screenshot' do
              std_api_v2 do
                entry = ComplaintEntry.find(params[:complaint_entry_id])
                return { image_data: '' }.to_json unless entry
                record = entry.complaint_entry_screenshot
                return { image_data: '' }.to_json unless record
                return { image_data: Base64.encode64(record.screenshot) }.to_json
              end
            end
            get ':complaint_entry_id/retake_screenshot' do
              std_api_v2 do
                entry = ComplaintEntry.find(params[:complaint_entry_id])
                ces = entry.complaint_entry_screenshot
                unless ces
                  ces = ComplaintEntryScreenshot.create(complaint_entry_id: entry.id )
                end
                ces.update(error_message:"Retaking screenshot please wait.", screenshot:nil)
                ces.grab_screenshot
              end
            end

            desc 'Retrieve current categories from expanding a complaint entry row'
            params do
              requires :id, type: Integer
            end
            post 'retrieve_current_categories' do
              std_api_v2 do
                complaint_entry = ComplaintEntry.find(params[:id])

                if complaint_entry.subdomain.present? || complaint_entry.path.present?
                  master_categories = complaint_entry.get_category_names_from_master
                else
                  master_categories = []
                end

                begin
                  wbrs_categories = complaint_entry.current_category_data
                rescue Exception => e
                  raise("having trouble with WBRS setting category to empty string : #{e.message}")
                end
                # Pull category from SDS
                sds_params = {}

                if complaint_entry.entry_type == 'URI/DOMAIN'
                  # get category for full uri
                  sds_params['url'] = complaint_entry.uri
                elsif complaint_entry.entry_type == 'IP'
                  sds_params['url'] = complaint_entry.ip_address
                end

                begin
                  sds_category = Sbrs::ManualSbrs.call_wbrs_webcat(sds_params, type: 'wbrs')
                rescue Exception => e
                  raise("having trouble with SDS setting category to empty string : #{e.message}")
                end

                sds_domain_category = ""
                if complaint_entry.entry_type == 'URI/DOMAIN'
                  # get category for domain
                  sds_params['url'] = complaint_entry.domain
                  sds_domain_category = Sbrs::ManualSbrs.call_wbrs_webcat(sds_params, type: 'wbrs')
                end
                {master_categories: master_categories, current_category_data: wbrs_categories,
                 sds_category: sds_category, sds_domain_category: sds_domain_category}.to_json
              end
            end


            desc 'Retrieve current categories by URL only (not complaint entry ID)'
            params do
              requires :domain, type: String # Must be in the form of "domain.com" only, no http/s or path
            end
            post 'retrieve_current_categories_by_url' do
              std_api_v2 do
                complaint_entry = ComplaintEntry.where(:domain => params[:domain]).order(:created_at).last

                if complaint_entry.subdomain.present? || complaint_entry.path.present?
                  master_categories = complaint_entry.get_category_names_from_master
                else
                  master_categories = []
                end

                wbrs_categories = complaint_entry.current_category_data

                # Pull category from SDS
                sds_params = {}

                if complaint_entry.entry_type == 'URI/DOMAIN'
                  sds_params['url'] = complaint_entry.uri
                elsif complaint_entry.entry_type == 'IP'
                  sds_params['url'] = complaint_entry.ip_address
                end

                sds_category = Sbrs::ManualSbrs.call_wbrs_webcat(sds_params, type: 'wbrs')

                {master_categories: master_categories, current_category_data: wbrs_categories,
                 sds_category: sds_category, complaint_entry_id: complaint_entry.id }.to_json
              end
            end


            desc 'Retrieve category names from master domain'
            params do
              requires :id, type: Integer
            end
            post 'retrieve_category_names_from_master' do
              std_api_v2 do
                complaint_entry = ComplaintEntry.find(params[:id])
                complaint_entry.get_category_names.to_json
              end
            end

            desc 'Inherit categories from master domain'
            params do
              requires :id, type: Integer
            end
            post 'inherit_categories_from_master_domain' do
              std_api_v2 do
                complaint_entry = ComplaintEntry.find(params[:id])
                complaint_entry.inherit_categories(ip_or_uri: complaint_entry.uri, description:'Inherited from master domain', user: current_user.email)
              end
            end

            desc 'Update several entries at once'
            params do
              requires :data, type: Array
            end

            post 'master_submit' do
              std_api_v2 do
                response = []
                permitted_params['data'].each do |entry|
                  begin
                    if entry['error'] == false
                      complaint_entry = ComplaintEntry.find(entry['entry_id'])
                      uri_as_categorized = entry['uri_as_categorized'].blank? ? complaint_entry.uri : entry['uri_as_categorized']
                      complaint_entry.change_category( entry['prefix'],
                                                       entry['categories'],
                                                       entry['category_names'],
                                                       entry['status'],
                                                       entry['comment'],
                                                       entry['resolution_comment'],
                                                       uri_as_categorized,
                                                       current_user, "")

                      Thread.new { ComplaintEntryPreload.generate_preload_from_complaint_entry(complaint_entry) }
                      if complaint_entry.complaint.ticket_source != Complaint::SOURCE_RULEUI
                        message = Bridge::ComplaintUpdateStatusEvent.new
                        message.post_complaint(complaint_entry.complaint)
                      end

                      response.push({error: false, entry_id: entry['entry_id'], row_id: entry['row_id'], status: complaint_entry.status, resolution: entry['status'],
                                         comment: entry['comment'], resolution_comment: entry['resolution_comment'], categories: entry['categories'],
                                         category_names: entry['category_names']})
                    elsif entry['error'] == true && entry['reason'] == 'nil_categories'
                      response.push({error: true, entry_id: entry['entry_id'], reason: 'nil_categories'})
                    end
                  rescue Exception => e
                    response.push({error: true, entry_id: entry['entry_id'], reason: 'api'})
                    next
                  end
                end
                response.to_json
              end
            end

            desc "get domain history for webcat research tool"
            params do
              optional :domain, type: String
            end

            get 'get_domain_history' do

              response = {}
              response[:status] = "success"
              response[:data] = []

              pre_raw_records = []

              prefix_records = Wbrs::Prefix.where({:urls => [URI.escape(SimpleIDN.to_ascii(params[:domain]))]})
              prefix_records.each do |prefix_record|
                history_records = Wbrs::HistoryRecord.where({:prefix_id => prefix_record.prefix_id})
                pre_raw_records += history_records
              end
              clean_domain = URI.escape(SimpleIDN.to_ascii(params[:domain]))

              rule_lib_records = Wbrs::Prefix.get_certainty_sources_for_urls([clean_domain], 0)[clean_domain]
              if rule_lib_records.blank?
                rule_lib_records = []
              end
              raw_records = []

              ### this change is to de-duplicate the records that come in from a combo Prefix and HistoryRecord call
              # uniq doesn't work, and it needs to be tested against 3 different attributes.
              pre_raw_records.each do |raw_record|
                skip = false
                raw_records.each do |raw_check|
                  if raw_record.event_id == raw_check.event_id && raw_record.prefix_id == raw_check.prefix_id && raw_record.category.category_id == raw_check.category.category_id
                    skip = true
                  end
                end
                if skip == false
                  raw_records << raw_record
                end
              end

              raw_records = raw_records.sort_by {|history| DateTime.parse(history.time)}.reverse

              base_score = Sbrs::Base.combo_call_sds_v3(url_from_prefix, [])["wbrs"]["score"] rescue "no data or error"

              response[:data] << {:is_important => ComplaintEntry.self_importance(params[:domain]),
                                  :category => nil,
                                  :url => params[:domain],
                                  :domain => nil,
                                  :subdomain => nil,
                                  :path => nil,
                                  :action => nil,
                                  :confidence => nil,
                                  :score => base_score,
                                  :time_of_action => nil,
                                  :description => "baseline domain",
                                  :user => nil,
                                  :entry_id => nil,
                                  :complaint_id => nil}

              raw_records.each do |record|
                prefix = prefix_records.find {|prec| prec.prefix_id == record.prefix_id}
                url_from_prefix = Complaint.compile_parts_to_uri({"subdomain" => prefix.subdomain, "domain" => prefix.domain, "path" => prefix.path })
                data_point = {}

                entry_id = nil
                complaint_id = nil

                complaint_entry = ComplaintEntry.where("uri like '%#{url_from_prefix}%'").last

                if complaint_entry.present?
                  entry_id = complaint_entry.id
                  complaint_id = complaint_entry.complaint_id
                end

                record_score = Sbrs::Base.combo_call_sds_v3(url_from_prefix, [])["wbrs"]["score"] rescue "no data or error"

                data_point[:is_important] = ComplaintEntry.self_importance(url_from_prefix)
                data_point[:category] = record.category.descr
                data_point[:url] = SimpleIDN.to_unicode(url_from_prefix)
                data_point[:domain] = SimpleIDN.to_unicode(prefix.domain)
                data_point[:subdomain] = SimpleIDN.to_unicode(prefix.subdomain)
                data_point[:path] = SimpleIDN.to_unicode(prefix.path)
                data_point[:action] = record.action
                data_point[:confidence] = record.confidence
                data_point[:score] = record_score
                data_point[:time_of_action] = record.time
                data_point[:description] = record.description
                data_point[:user] = record.user
                data_point[:entry_id] = entry_id
                data_point[:complaint_id] = complaint_id

                response[:data] << data_point
              end

              rule_lib_records.each do |record|

                data_point = {}

                url_from_prefix = Complaint.compile_parts_to_uri({"subdomain" => record["subdomain"], "domain" => record["domain"], "path" => record["path"] })

                entry_id = nil
                complaint_id = nil

                complaint_entry = ComplaintEntry.where("uri like '%#{url_from_prefix}%'").last

                if complaint_entry.present?
                  entry_id = complaint_entry.id
                  complaint_id = complaint_entry.complaint_id
                end

                record_score = Sbrs::Base.combo_call_sds_v3(url_from_prefix, [])["wbrs"]["score"] rescue "no data or error"

                data_point[:is_important] = ComplaintEntry.self_importance(url_from_prefix)
                data_point[:category] = record["description"]
                data_point[:url] = SimpleIDN.to_unicode(url_from_prefix)
                data_point[:domain] = SimpleIDN.to_unicode(record["domain"])
                data_point[:subdomain] = SimpleIDN.to_unicode(record["subdomain"])
                data_point[:path] = SimpleIDN.to_unicode(record["path"])
                data_point[:action] = ""
                data_point[:confidence] = "#{record["confidence"]}|certainty: #{record["certainty"]} "
                data_point[:score] = record_score
                data_point[:time_of_action] = ""
                data_point[:description] = record["source_description"]
                data_point[:user] = "Rulelib Database"
                data_point[:entry_id] = entry_id
                data_point[:complaint_id] = complaint_id

                response[:data] << data_point
              end


              response

            end

            desc 'Get XBRS data on complaint url'
            params do
              requires :url, type: String
            end

            post 'xbrs' do
              data = K2::History.url_lookup(params['url']).body.dig('queryResults')&.first&.fetch('timelines') || []
              
              formatted_data = []
              formatted_data = data.each_with_object([]) do |item, result|
                row = {}
                row[:time] = Time.at(item['time'] / 1000).strftime('%B %e, %Y at %I:%M %p')
                row[:score] = item['score']
                row[:v2] = item['aups'].select { |aup| aup['version'] == 'V2' }.pluck('cat').join(', ')
                row[:v3] = item['aups'].select { |aup| aup['version'] == 'V3' }.pluck('cat').join(', ')
                row[:threatCats] = item['threatCats'].join(', ')
                row[:ruleHits] = item['ruleHits'].join(', ')
                result << row
              end
              { status: 'success', data: formatted_data }
            end

            desc "Reopen a complaint entry"
            params do
              requires :complaint_entry_id, type: Integer
            end

            post 'reopen_complaint_entry' do
              begin
                entry = ComplaintEntry.where(:id => permitted_params[:complaint_entry_id]).first
                if entry.reopen
                  {:status => "success"}
                else
                  {:status => "error"}
                end
              rescue
                {:status => "error"}
              end
            end

            params do
              requires :complaint_entries, type: Array[Integer]
              requires :resolution, type: String
              optional :internal_comment, type: String
              optional :customer_facing_comment, type: String
            end
            post 'update_resolution' do
              std_api_v2 do
                confirmations = []
                permitted_params[:complaint_entries].each do |entry|
                  begin
                    complaint_entry = ComplaintEntry.find(entry)
                    processed = complaint_entry.process_resolution_changes(permitted_params[:resolution], permitted_params[:internal_comment], permitted_params[:customer_facing_comment], current_user)

                    confirmations << processed
                  rescue
                    confirmations << {status: 'ERROR', id: entry, resolution: permitted_params[:resolution], internal_comment: permitted_params[:internal_comment],
                                      customer_facing_comment: permitted_params[:customer_facing_comment],
                                      message: "Database error occurred while processing Complaint Entry (#{complaint_entry.present? ? complaint_entry.hostlookup : "Entry not found"})"}
                  end
                end
                confirmations.to_json
              end
            end
          end
        end
      end
    end
  end
end
