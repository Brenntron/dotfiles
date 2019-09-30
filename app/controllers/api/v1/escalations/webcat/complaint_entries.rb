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


            desc 'update an entry '
            params do
              requires :id, type: Integer, desc:'complaint entry id'
              requires :prefix, type: String, desc: 'the url to categorize'
              requires :categories, type: String, desc: 'a list of categories to assign to this prefix'
              requires :category_names, type: String, desc: 'a list of category names to assign to Complaint Entry record'
              requires :status, type: String, desc: 'setting the status of the entry'
              optional :comment, type: String, desc: 'internal comment'
              optional :resolution_comment, type: String, desc: 'resolution comment for the customer'
            end
            post 'update'do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'],
                                       permitted_params['categories'],
                                       permitted_params['category_names'],
                                       permitted_params['status'],
                                       permitted_params['comment'],
                                       permitted_params['resolution_comment'],
                                       current_user, "")
                ComplaintEntryPreload.generate_preload_from_complaint_entry(entry)
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


            desc 'update a high telemetry entry'
            params do
              requires :id, type:Integer, desc:'complaint entry id'
              requires :prefix, type:String, desc: 'the url to categorize'
              requires :commit, type: String, desc: 'set this if you want to commit a pending complaint'
              requires :status, type: String, desc: 'this is the status of this complaint Entry'
              requires :categories, type: String, desc: 'a list of categories to assign to this prefix'
              requires :category_names,type: String, desc: 'a list of category names to assign to Complaint Entry record'
              optional :comment, type: String, desc: 'resolution comment for the customer'
              optional :resolution_comment, type:String, desc: 'an internal comment'
            end
            post 'update_pending' do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'],
                                       permitted_params['categories'],
                                       permitted_params['category_names'],
                                       permitted_params['status'],
                                       permitted_params['comment'],
                                       permitted_params['resolution_comment'],
                                       current_user, permitted_params['commit'])
                if entry.complaint.ticket_source != Complaint::SOURCE_RULEUI
                  message = Bridge::ComplaintUpdateStatusEvent.new
                  message.post_complaint(entry.complaint)
                end

              rescue Exception => e
                return e.message
              end
              {entry_id: entry.id, domain: entry.domain, subdomain: entry.subdomain, path: entry.path,
               categories: entry.url_primary_category, uri: entry.uri, status:entry.status,
               entry_resolution:permitted_params['commit'], was_dismissed: entry.was_dismissed?}.to_json
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
                    error_message = ["---The following entrys could not be taken because---"]
                  else
                    error_message = ["---Some entries were taken however, The following entrys could not be taken because---"]
                  end
                  error_entry_ids.keys.each do |key|
                    error_message << "#{key}: entry IDs -> #{error_entry_ids[key].to_sentence}"
                  end
                  unless error_count == permitted_params['complaint_entry_ids'].count
                    error_message << "Please refresh the page to pickup the latest changes."
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
                  status = ComplaintEntry.find(id).return_complaint
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
                    error_message = ["---The following entrys could not be returned because---"]
                  else
                    error_message = ["---Some entries were returned however, The following entrys could not be returned because---"]
                  end
                  error_entry_ids.keys.each do |key|
                    error_message << "#{key}: entry IDs -> #{error_entry_ids[key].to_sentence}"
                  end
                  unless error_count == permitted_params['complaint_entry_ids'].count
                    error_message << "Please refresh the page to pickup the latest changes."
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
                    if prefix.subdomain == url[:subdomain] && prefix.path == url[:path]
                      prefix_id = prefix.prefix_id

                      prefix_history = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| DateTime.parse(history.time)}.reverse
                    end
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
                 sds_category: sds_category }.to_json
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
                    binding.pry
                    if entry['error'] == false
                      complaint_entry = ComplaintEntry.find(entry['entry_id'])
                      complaint_entry.change_category( entry['prefix'],
                                                       entry['categories'],
                                                       entry['category_names'],
                                                       entry['status'],
                                                       entry['comment'],
                                                       entry['resolution_comment'],
                                                       current_user, "")

                      ComplaintEntryPreload.generate_preload_from_complaint_entry(complaint_entry)
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

            desc 'Get XBRS data on complaint url'
            params do
              requires :url, type: String
            end

            post 'xbrs' do
              #raise 'simulated breakage'
              response = Xbrs::GetXbrs.by_domain(permitted_params['url'])
              return [] if response.is_a?(Hash) && response[:error].present?
              data = response.last['data']
              columns = response.last['legend']

              mtime_column_index = nil
              ctime_column_index = nil

              columns.each_with_index do |col, index|
                if col == 'ctime'
                  ctime_column_index = index
                end
                if col == 'mtime'
                  mtime_column_index = index
                end
              end

              formatted_data = []

              data.each do |datum|
                if ctime_column_index
                  datum[ctime_column_index] = Time.at(datum[ctime_column_index])
                end
                if mtime_column_index
                  datum[mtime_column_index] = Time.at(datum[mtime_column_index])
                end

                formatted_data << datum
              end

              {:status => "success", :data => formatted_data, :columns => columns}
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

          end
        end
      end
    end
  end
end
