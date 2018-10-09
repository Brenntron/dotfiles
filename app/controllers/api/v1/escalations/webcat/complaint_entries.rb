module API
  module V1
    module Escalations
      module Webcat
        class ComplaintEntries < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/complaint_entries" do

            before do
              PaperTrail.whodunnit = current_user.id if current_user.present?
            end

            desc 'get all complaint entries'
            params do
              optional :filter_by, type: String, desc: 'filter entries by this value'
              optional :self_review, type: Boolean, desc: 'a flag that allows users to review their own categorizations'
              optional :search, type: String, desc: 'search entries by this value'

              optional :customer, type: Hash do
                optional :name, type: String
                optional :email, type: String
                optional :company_name, type: String
              end

              optional :complaint_entries, type: Hash do
                optional :ip_or_uri, type: String
                optional :resolution, type: String
                optional :category, type: String
                optional :status, type: String
                optional :complaint_id, type: Array
              end
              optional :search_type, type: String
              optional :search_name, type: String
              optional :description, type: String
              optional :submitted_older, type: Date
              optional :submitted_newer, type: Date
              optional :modified_older, type: Date
              optional :modified_newer, type: Date
              optional :channel, type: String
              optional :tags, type: Array
            end

            get "" do
              json_packet = []

              search_type = ComplaintEntry.get_search_type(permitted_params)
              search_name = permitted_params[:search_name] ? permitted_params[:search_name] : nil


              complaint_entries = ComplaintEntry.robust_search(search_type,
                                                               search_name: search_name,
                                                               params: permitted_params,
                                                               user: current_user)

              if complaint_entries
                complaint_entries.each do |complaint_entry|
                  complaint_entry_packet = {}
                  complaint_entry_packet[:age] = ComplaintEntry.what_time_is_it((Time.now - complaint_entry.created_at).to_i)
                  complaint_entry_packet[:age_int] = (Time.now - complaint_entry.created_at).to_i
                  complaint_entry_packet[:complaint_id] = complaint_entry&.complaint.id
                  complaint_entry_packet[:entry_id] = complaint_entry.id

                  complaint_entry_packet[:assigned_to] = complaint_entry.user&.display_name
                  complaint_entry_packet[:status] = complaint_entry.status
                  complaint_entry_packet[:created_at] = complaint_entry.created_at.strftime('%Y-%m-%d %H:%M:%S')
                  complaint_entry_packet[:customer_name] = complaint_entry.complaint&.customer&.name # Customer name

                  complaint_entry_packet[:category] = complaint_entry.url_primary_category
                  complaint_entry_packet[:resolution]= complaint_entry.resolution
                  complaint_entry_packet[:internal_comment] = complaint_entry.internal_comment
                  complaint_entry_packet[:resolution_comment] = complaint_entry.resolution_comment

                  complaint_entry_packet[:subdomain] = complaint_entry.subdomain
                  complaint_entry_packet[:domain] = complaint_entry.domain
                  complaint_entry_packet[:path] = complaint_entry.path
                  complaint_entry_packet[:ip_address] = complaint_entry.ip_address
                  if complaint_entry.wbrs_score.present?
                    complaint_entry_packet[:wbrs_score] = complaint_entry.wbrs_score.to_d.truncate(2).to_f
                  else
                    complaint_entry_packet[:wbrs_score] = ''
                  end
                  complaint_entry_packet[:is_important] = complaint_entry.is_important
                  complaint_entry_packet[:was_dismissed] = complaint_entry.was_dismissed?
                  complaint_entry_packet[:viewable] = complaint_entry.viewable

                  if !complaint_entry.suggested_disposition.nil?
                    first_category = complaint_entry.suggested_disposition.split(',')
                    if first_category.length > 1
                      complaint_entry_packet[:suggested_category] = '<span class= "esc-tooltipped" title=" ' + complaint_entry.suggested_disposition.gsub(',',', ') + ' "> '  + first_category.first + ' + </span>'
                    else
                      complaint_entry_packet[:suggested_category] = first_category.first
                    end
                  else
                    complaint_entry_packet[:suggested_category] = ''
                  end

                  complaint_entry_packet[:submitter_type] = complaint_entry.complaint.submitter_type
                  complaint_entry_packet[:company_name] = complaint_entry.complaint&.customer&.company&.name
                  complaint_entry_packet[:tags] = {}
                  complaint_entry_packet[:tags] = complaint_entry.complaint.complaint_tags.map{|tag| tag&.name }

                  complaint_entry_packet[:screen_shot_error] = complaint_entry&.complaint_entry_screenshot&.error_message

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

                  #fake it til they make it
                  # fake_ass_bullshit = {}
                  # fake_ass_bullshit[77] = {:is_active => 1, :mnemonic => "alc", :category_id => 77, :prefix_id => 12, :confidence => 1, :name => "Alcohol", :long_description => "Good ole fun juice"}
                  # fake_ass_bullshit[77][:certainty] = [{:source => "iwf", :source_category => "busi - Business and Industry", :source_certainty => '1000'}, {:source => "other_multi_eka", :source_category => "ngo - Non-government Organization", :source_certainty => '1000'}]
                  # fake_ass_bullshit[88] = {:is_active => 1, :mnemonic => "auct", :category_id => 88, :prefix_id => 12, :confidence => 2, :name => "Auctions", :long_description => "Buy stuff from cool people who yell."}
                  # fake_ass_bullshit[88][:certainty] = [{:source => "iwf", :source_category => "busi - Business and Industry", :source_certainty => '500'}, {:source => "other_multi_eka", :source_category => "ngo - Non-government Organization", :source_certainty => '1000'}]
                  #
                  # complaint_entry_packet[:current_categories] = fake_ass_bullshit

                  #each row has available to it: action, confidence, description, even_id, prefix_id, time, user, category.   "category" has its own hash
                  #which has available to it: mnem, descr, category_id, desc_long

                  complaint_entry_packet[:entry_history] = {}
                  if complaint_entry.complaint_entry_preload.present?
                    if complaint_entry.complaint_entry_preload.historic_category_information.present?
                      complaint_entry_packet[:entry_history][:domain_history] = complaint_entry.complaint_entry_preload.historic_category_information
                    else
                      complaint_entry_packet[:entry_history][:domain_history] = complaint_entry.historic_category_data
                    end
                  else
                    complaint_entry_packet[:entry_history][:domain_history] = complaint_entry.historic_category_data
                  end

                  complaint_entry_packet[:entry_history][:complaint_history] = complaint_entry.compose_versions

                  json_packet << complaint_entry_packet
                end
              end
              {:status => "success", :data => json_packet}.to_json

            end


            desc 'update an entry '
            params do
              requires :id, type: Integer, desc:'complaint entry id'
              requires :prefix, type: String, desc: 'the url to categorize'
              requires :categories, type: String, desc: 'a list of categories to assign to this prefix'
              requires :status, type: String, desc: 'setting the status of the entry'
              optional :comment, type: String, desc: 'internal comment'
              optional :resolution_comment, type: String, desc: 'resolution comment for the customer'
            end
            post 'update'do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'],permitted_params['categories'],
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
              {status:entry.status, entry_resolution:permitted_params['status']}.to_json
            end


            desc 'update a high telemetry entry'
            params do
              requires :id, type:Integer, desc:'complaint entry id'
              requires :prefix, type:String, desc: 'the url to categorize'
              requires :commit, type: String, desc: 'set this if you want to commit a pending complaint'
              requires :status, type: String, desc: 'this is the status of this complaint Entry'
              requires :categories, type: String, desc: 'a list of categories to assign to this prefix'
              optional :comment, type: String, desc: 'resolution comment for the customer'
              optional :resolution_comment, type:String, desc: 'an internal comment'
            end
            post 'update_pending' do
              begin
                entry = ComplaintEntry.find(permitted_params['id'])
                entry.change_category( permitted_params['prefix'], permitted_params['categories'],
                                    permitted_params['status'],
                                    permitted_params['comment'],permitted_params['resolution_comment'],
                                    current_user, permitted_params['commit'])

                message = Bridge::ComplaintUpdateStatusEvent.new
                message.post_complaint(entry.complaint)

              rescue Exception => e
                return e.message
              end
              {status:entry.status, entry_resolution:permitted_params['commit'], was_dismissed: entry.was_dismissed?}.to_json
            end


            desc 'take entry'
            params do
              requires :complaint_entry_ids, type: Array[Integer], desc: 'ComplaintEntry ids'
            end
            post 'take_entry' do
              begin
                permitted_params['complaint_entry_ids'].each do |id|
                  ComplaintEntry.find(id).take_complaint(current_user)
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
                permitted_params['complaint_entry_ids'].each do |id|
                  ComplaintEntry.find(id).return_complaint(current_user)
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
              begin
                prefix_id = Wbrs::Prefix.where(:urls => [permitted_params['url']]).first.prefix_id
                response = Wbrs::HistoryRecord.where({:prefix_id => prefix_id}).sort_by {|history| history.time}.reverse

                render response.to_json
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

          end
        end
      end
    end
  end
end
