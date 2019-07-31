class Escalations::Webrep::DisputesController < ApplicationController
  load_and_authorize_resource class: 'Dispute'

  before_action :require_login

  def index
    respond_to do |format|
      format.html
      format.xlsx do
        index_params = JSON.parse(params['data_json'])
        search_type = index_params['search_type']
        search_name = 'advanced' == search_type ? nil : index_params['search_name']
        @disputes = Dispute.robust_search(search_type,
                                          search_name: search_name,
                                          params: index_params,
                                          user: current_user)
        contents = RubyXL::Workbook.new
        @worksheet = contents[0]

        def singlesheet_insert_row_with_data(data, format = nil)
          data_insertion_index = @worksheet.sheet_data.rows.count
          data.each_with_index do |new_data, i|
            @worksheet.add_cell(data_insertion_index, i, new_data)
            case format
              when "bold"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
              when "h1"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
                @worksheet.sheet_data[data_insertion_index][i].change_font_size(14)
              when "h2"
                @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
                @worksheet.sheet_data[data_insertion_index][i].change_font_size(12)
            end
          end
        end

        dispute_headers = ['Priority',
                           'Case ID',
                           'Status',
                           'Entry Count',
                           'Owner',
                           'Customer Name',
                           'Customer Email',
                           'Customer Company',
                           'Company URL',
                           'Time Submitted',
                           'Last Updated',
                           'Age',
                           'Dispute Entry',
                           'Dispute Entry Status',
                           'Suggested Disposition',
                           'Category',
                           'WBRS Score',
                           'WBRS Total Rule Hits',
                           'SBRS Score',
                           'SBRS Total Rule Hits',
                           'Important?',
                           'Resolution',
                           'Last Comment Date',
                           'Comment Count',
                           'Resolution Comments']
        singlesheet_insert_row_with_data(dispute_headers, "h1")

        @disputes.each do |dispute|
          dispute.dispute_entries.each do |dispute_entry|
            singlesheet_insert_row_with_data([ dispute_entry.dispute.priority,
                                               dispute_entry.dispute.case_id_str,
                                               dispute_entry.dispute.status,
                                               dispute_entry.dispute.dispute_entries.count,
                                               dispute_entry.dispute.user.cvs_username,
                                               dispute_entry.dispute.customer.name,
                                               dispute_entry.dispute.customer.email,
                                               dispute_entry.dispute.customer.company.name,
                                               dispute_entry.dispute.org_domain,
                                               dispute_entry.dispute.case_opened_at.strftime("%FT%T"),
                                               dispute_entry.dispute.updated_at.strftime("%FT%T"),
                                               ApplicationRecord.humanize_secs(Time.now - dispute_entry.dispute.case_opened_at),
                                               dispute_entry.hostlookup,
                                               dispute_entry.status,
                                               dispute_entry.suggested_disposition,
                                               dispute_entry.primary_category,
                                               dispute_entry.wbrs_score,
                                               dispute_entry.dispute_rule_hits.wbrs_rule_hits.count,
                                               dispute_entry.sbrs_score,
                                               dispute_entry.dispute_rule_hits.sbrs_rule_hits.count,
                                               dispute_entry.is_important,
                                               dispute_entry.resolution,
                                               dispute_entry.latest_comment_date,
                                               dispute_entry.dispute.dispute_comments.count,
                                               dispute_entry.resolution_comment ])
          end
        end

        send_data contents.stream.string, filename: "disputes_search_#{Time.now.utc.iso8601}.xlsx", disposition: 'attachment'
      end
    end
  end

  def show
    @dispute = Dispute.eager_load([:dispute_comments, :dispute_emails]).eager_load(:dispute_entries => [:dispute_rule_hits, :dispute_entry_preload]).where(:id => params[:id]).first
    @versioned_items = @dispute.compose_versioned_items

    @entries = @dispute.dispute_entries

    @entries.each do |entry|
      if entry.dispute_entry_preload.blank?
        Preloader::Base.fetch_all_api_data(entry.hostlookup, entry.id)
      end
    end

    @dispute.peek(user: current_user)

    #@entries.each do |entry|
      #todo: do lazy load style checking with blacklist here
      #entry.blacklist(reload: true)

    #end
  end

  def update
  end

  # TODO We should not have a 400 line method in a controller.
  # TODO avoid defining methods in the body of other methods.
  def dashboard
    respond_to do |format|
      format.html
      format.xlsx do
        #
        # This is a GET request;
        # Expected params:
        #
        # mytickets - bool
        # myteamtickets - bool
        # alltickets - Not implemented
        # customtickets - Not implemented
        # startdate - datetime (the JS making the request gets from localstorage object)
        # enddate - datetime (the JS making the request gets from localstorage object)
        #

        def insert_row_with_data(data, filename, sheetname, format = nil)
          worksheet = filename[sheetname]
          data_insertion_index = worksheet.sheet_data.rows.count
          data.each_with_index do |new_data, i|
            worksheet.add_cell(data_insertion_index, i, new_data)
            case format
            when "bold"
              worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
            when "h1"
              worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
              worksheet.sheet_data[data_insertion_index][i].change_font_size(14)
            when "h2"
              worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
              worksheet.sheet_data[data_insertion_index][i].change_font_size(12)
            end
          end
        end

        def insert_adhoc_data(data, xpos, ypos, filename, sheetname, format = nil)
          # Insert a single data value into an arbitrary cell. `xpos` and `ypos`
          # are integers specifying what cell to insert into.
          worksheet = filename[sheetname]
          worksheet.add_cell(xpos, ypos, data)
          case format
          when "bold"
            worksheet.sheet_data[xpos][ypos].change_font_bold(true)
          when "h1"
            worksheet.sheet_data[xpos][ypos].change_font_bold(true)
            worksheet.sheet_data[xpos][ypos].change_font_size(14)

          when "h2"
            worksheet.sheet_data[xpos][ypos].change_font_bold(true)
            worksheet.sheet_data[xpos][ypos].change_font_size(12)

          end

        end

        @spreadsheet_directory = Dir.mktmpdir

        if params['mytickets'] == "true"
          mytickets_file = File.new("#{@spreadsheet_directory}/my-tickets_#{Time.now.utc.iso8601}.xlsx", 'w+')
          mytickets_xlsx = RubyXL::Workbook.new
          mytickets_workbook_names = {
              :my_open_tickets => 'My Open Tickets',
              :my_closed_tickets => 'My Closed Tickets',
              :total_ticket_entries_closed => 'Total Ticket Entries Closed',
              :time_to_close_tickets => 'Time to Close Tickets',
              :ticket_submitted_by_submitter_type => 'Tickets Submitted by Submitter Type',
              :closed_email_by_resolution => 'Closed Email Entries by Resolution',
              :closed_web_by_resolution => 'Closed Web Entries by Resolution'
          }
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:my_open_tickets])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:my_closed_tickets])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:total_ticket_entries_closed])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:time_to_close_tickets])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:ticket_submitted_by_submitter_type])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:closed_email_by_resolution])
          mytickets_xlsx.add_worksheet(mytickets_workbook_names[:closed_web_by_resolution])


          # Build the headers of each individual worksheet
          my_open_tickets_headers = ['Case ID', 'Submitter Type', 'Ticket Type', 'Priority', 'Dispute Preview', 'Last Comment Date', 'Comment Count', 'Entry Count']
          my_closed_tickets_headers = ['Case ID', 'Submitter Type', 'Ticket Type', 'Priority', 'Dispute Preview', 'Time to Close', 'Entry Count']
          total_ticket_entries_closed_headers = ['Date', 'Web', 'Email', 'Web_Email', 'Total']
          time_to_close_tickets_headers = ['Ticket', 'Time (hrs)']
          ticket_submitted_by_submitter_type_headers = ['Date', 'Customer', 'Guest']
          closed_email_by_resolution_headers = ['Resolution', 'Count', 'Percent']
          closed_web_by_resolution_headers = ['Resolution', 'Count', 'Percent']
          insert_row_with_data(my_open_tickets_headers, mytickets_xlsx, mytickets_workbook_names[:my_open_tickets], "h1")
          insert_row_with_data(my_closed_tickets_headers, mytickets_xlsx, mytickets_workbook_names[:my_closed_tickets], "h1")
          insert_row_with_data(total_ticket_entries_closed_headers, mytickets_xlsx, mytickets_workbook_names[:total_ticket_entries_closed], "h1")
          insert_row_with_data(time_to_close_tickets_headers, mytickets_xlsx, mytickets_workbook_names[:time_to_close_tickets], "h1")
          insert_row_with_data(ticket_submitted_by_submitter_type_headers, mytickets_xlsx, mytickets_workbook_names[:ticket_submitted_by_submitter_type], "h1")
          insert_row_with_data(closed_email_by_resolution_headers, mytickets_xlsx, mytickets_workbook_names[:closed_email_by_resolution], "h1")
          insert_row_with_data(closed_web_by_resolution_headers, mytickets_xlsx, mytickets_workbook_names[:closed_web_by_resolution], "h1")

          # Insert data in each sheet

          # My Open Tickets
          my_open_tickets_data = Dispute.open_tickets_report([current_user], params[:startdate], params[:enddate])
          my_open_tickets_data[:table_data].each do |d|
            data_values = [d[:case_number], d[:submitter_type], d[:submission_type], d[:priority], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).gsub(/ *\d+$/, ''), d[:last_comment_date], d[:comment_count], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).scan(/\d+/).last]
            # The Rails `strip_tags` method doesn't work directly in this controller and I don't know why.
            insert_row_with_data(data_values, mytickets_xlsx, mytickets_workbook_names[:my_open_tickets])
          end


          # My Closed Tickets
          my_closed_tickets_data = Dispute.closed_tickets_report([current_user], params[:startdate], params[:enddate])
          my_closed_tickets_data[:table_data].each do |d|
            data_values = [d[:case_number], d[:submitter_type], d[:submission_type], d[:priority], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).gsub(/ *\d+$/, ''), d[:time_to_close], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).scan(/\d+/).last]
            insert_row_with_data(data_values, mytickets_xlsx, mytickets_workbook_names[:my_closed_tickets])
          end


          # Total ticket entries closed
          @total_ticket_entries_closed_data = Dispute.ticket_entries_closed_by_day_report([current_user], params[:startdate], params[:enddate])
          @total_ticket_entries_closed_data[:report_labels].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @total_ticket_entries_closed_data[:report_w_data][i]
            final_row << @total_ticket_entries_closed_data[:report_e_data][i]
            final_row << @total_ticket_entries_closed_data[:report_ew_data][i]
            final_row << @total_ticket_entries_closed_data[:report_total_data][i]
            insert_row_with_data(final_row, mytickets_xlsx, mytickets_workbook_names[:total_ticket_entries_closed])
          end

          # Time to close tickets
          @time_to_close_tickets_data = Dispute.ticket_time_to_close_report(current_user.id, params[:startdate], params[:enddate])
          @time_to_close_tickets_data[:ticket_numbers].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @time_to_close_tickets_data[:close_times][i]
            insert_row_with_data(final_row, mytickets_xlsx, mytickets_workbook_names[:time_to_close_tickets])
          end
          time_to_close_tickets_average = @time_to_close_tickets_data[:close_times].inject{ |sum, el| sum + el }.to_f / @time_to_close_tickets_data[:close_times].size
          insert_adhoc_data("Average Time to Close", 0, 2, mytickets_xlsx, mytickets_workbook_names[:time_to_close_tickets], "h1")
          insert_adhoc_data(time_to_close_tickets_average, 1, 2, mytickets_xlsx, mytickets_workbook_names[:time_to_close_tickets])


          # Ticket Submitted by Submitter Type
          @ticket_submitted_by_submitter_type_data = Dispute.tickets_submitted_by_submitter_per_day(params[:startdate], params[:enddate])
          @ticket_submitted_by_submitter_type_data[:chart_labels].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @ticket_submitted_by_submitter_type_data[:customer_chart_data][i]
            final_row << @ticket_submitted_by_submitter_type_data[:guest_chart_data][i]
            insert_row_with_data(final_row, mytickets_xlsx, mytickets_workbook_names[:ticket_submitted_by_submitter_type])
          end

          # Closed Email by Resolution
          closed_email_by_resolution_data = Dispute.closed_ticket_entries_by_resolution_report([current_user], params[:startdate], params[:enddate], "E")
          closed_email_by_resolution_data[:table_data].each do |d|
            data_values = [d[:resolution], d[:count], d[:percent]]
            insert_row_with_data(data_values, mytickets_xlsx, mytickets_workbook_names[:closed_email_by_resolution])
          end


          # Closed Web by Resolution
          closed_web_by_resolution_data = Dispute.closed_ticket_entries_by_resolution_report([current_user], params[:startdate], params[:enddate], "W")
          closed_web_by_resolution_data[:table_data].each do |d|
            data_values = [d[:resolution], d[:count], d[:percent]]
            insert_row_with_data(data_values, mytickets_xlsx, mytickets_workbook_names[:closed_web_by_resolution])
          end

          # NOTE: Use the .delete method here with caution. For some reason,
          # deleting a single sheet, of any name, will also delete all other blank sheets in the file.
          # As long as you have your data inserted before you do this, nothing should go wrong.
          # I think this could be because of .rewinding and .reading the file later on,
          # but don't have time to look into it at the moment. Could also just be a bug in
          # RubyXL.
          mytickets_xlsx.worksheets.delete(mytickets_xlsx['Sheet1'])

          mytickets_xlsx.write(mytickets_file)
          mytickets_file.rewind
        end

        if params['myteamtickets'] == "true"
          myteamtickets_file = File.new("#{@spreadsheet_directory}/my-team-tickets_#{Time.now.utc.iso8601}.xlsx", 'w+')
          myteamtickets_xlsx = RubyXL::Workbook.new
          myteamtickets_workbook_names = {
              :open_team_tickets => 'Open Tickets',
              :closed_team_tickets => 'Closed Tickets',
              :average_time_to_close_tickets_by_owner => 'Average Time to Close Tickets',
              :ticket_resolution_by_owner => 'Ticket Resolution by Owner',
              :rule_hits_for_false_positive_resolutions => 'Rule Hits for False Positive Resolutions',
              :total_ticket_entries_closed => 'Total Ticket Entries Closed',
              :ticket_submitted_by_submitter_type => 'Tickets Submitted by Submitter Type',
              :closed_email_by_resolution => 'Closed Email Entries by Resolution',
              :closed_web_by_resolution => 'Closed Web Entries by Resolution'
          }
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:open_team_tickets])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:closed_team_tickets])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:average_time_to_close_tickets_by_owner])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:ticket_resolution_by_owner])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:rule_hits_for_false_positive_resolutions])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:total_ticket_entries_closed])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:ticket_submitted_by_submitter_type])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:closed_email_by_resolution])
          myteamtickets_xlsx.add_worksheet(myteamtickets_workbook_names[:closed_web_by_resolution])

          # Build headers of each individual worksheet

          open_team_tickets_headers = [
              'Case ID',
              'Owner',
              'Submitter Type',
              'Ticket Type',
              'Priority',
              'Dispute Preview',
              'Last Email Date',
              'Comment Count',
              'Entry Count']
          closed_team_tickets_headers = ['Case ID', 'Owner', 'Submitter Type', 'Ticket Type', 'Priority', 'Dispute Preview', 'Time to Close', 'Entry Count']
          average_time_to_close_by_owner_headers = ['Owner', 'Time (hrs)']
          ticket_resolution_by_owner_headers = ['Owner', 'Fixed FP', 'Fixed FN', 'Unchanged', 'Other']
          rule_hits_for_false_positive_resolutions_headers = ['Rules', 'Rule Hits']
          total_ticket_entries_closed_headers = ['Date', 'Web', 'Email', 'Web_Email', 'Total']
          ticket_submitted_by_submitter_type_headers = ['Date', 'Customer', 'Guest']
          closed_email_by_resolution_headers = ['Resolution', 'Count']
          closed_web_by_resolution_headers = ['Resolution', 'Count']

          insert_row_with_data(open_team_tickets_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:open_team_tickets], "h1")
          insert_row_with_data(closed_team_tickets_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_team_tickets], "h1")
          insert_row_with_data(average_time_to_close_by_owner_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:average_time_to_close_tickets_by_owner], "h1")
          insert_row_with_data(ticket_resolution_by_owner_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:ticket_resolution_by_owner], "h1")
          insert_row_with_data(rule_hits_for_false_positive_resolutions_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:rule_hits_for_false_positive_resolutions], "h1")
          insert_row_with_data(total_ticket_entries_closed_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:total_ticket_entries_closed], "h1")
          insert_row_with_data(ticket_submitted_by_submitter_type_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:ticket_submitted_by_submitter_type], "h1")
          insert_row_with_data(closed_email_by_resolution_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_email_by_resolution], "h1")
          insert_row_with_data(closed_web_by_resolution_headers, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_web_by_resolution], "h1")


          # Begin data insertion

          # My Team [open] Tickets
          open_team_tickets_data = Dispute.open_tickets_report(current_user.my_team, params[:startdate], params[:enddate])
          open_team_tickets_data[:table_data].each do |d|
            data_values = [
                d[:case_number],
                d[:owner],
                d[:submitter_type],
                d[:submission_type],
                d[:priority],
                ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).gsub(/ *\d+$/, ''),
                d[:last_email_date],
                d[:comment_count],
                ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).scan(/\d+/).last
            ]
            # The Rails `strip_tags` method doesn't work directly in this controller and I don't know why.
            insert_row_with_data(data_values, myteamtickets_xlsx, myteamtickets_workbook_names[:open_team_tickets])
          end

          # Closed Tickets
          closed_team_tickets_data = Dispute.closed_tickets_report(current_user.my_team, params[:startdate], params[:enddate])
          closed_team_tickets_data[:table_data].each do |d|
            data_values = [d[:case_number], d[:owner], d[:submitter_type], d[:submission_type], d[:priority], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).gsub(/ *\d+$/, ''), d[:time_to_close], ActionController::Base.helpers.strip_tags(d[:d_entry_preview]).scan(/\d+/).last]
            insert_row_with_data(data_values, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_team_tickets])
          end

          # Average time to close by owner

          @time_to_close_tickets_data = Dispute.average_time_to_close_tickets_by_ticket_owner(current_user.my_team, params[:startdate], params[:enddate])
          @time_to_close_tickets_data[:report_labels].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @time_to_close_tickets_data[:report_data][i]
            insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:average_time_to_close_tickets_by_owner])
          end


          # current_user.my_team.each do |t|
          #   @time_to_close_tickets_data = Dispute.ticket_time_to_close_report(t.id, params[:startdate], params[:enddate])
          #   @time_to_close_tickets_data[:ticket_numbers].each_with_index do |row, i|
          #     final_row = []
          #     final_row << t.cvs_username
          #     final_row << row
          #     final_row << @time_to_close_tickets_data[:close_times][i]
          #     insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:average_time_to_close_tickets_by_owner])
          #   end
          # end

          # Ticket Resolution by owner
          @ticket_resolution_by_owner_data = Dispute.ticket_entry_resolution_by_ticket_owner(current_user.my_team, params[:startdate], params[:enddate])
          @ticket_resolution_by_owner_data[:ticket_owners].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @ticket_resolution_by_owner_data[:fixed_fp_tickets][i]
            final_row << @ticket_resolution_by_owner_data[:fixed_fn_tickets][i]
            final_row << @ticket_resolution_by_owner_data[:unchanged_tickets][i]
            final_row << @ticket_resolution_by_owner_data[:other_tickets][i]
            insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:ticket_resolution_by_owner])
          end

          # Rule hits for false positive resolutions
          @rule_hits_for_false_positive_resolutions_data = Dispute.rulehits_for_false_positive_resolutions(current_user.my_team, params[:startdate], params[:enddate])
          @rule_hits_for_false_positive_resolutions_data[:rules].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @rule_hits_for_false_positive_resolutions_data[:rule_hits][i]
            insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:rule_hits_for_false_positive_resolutions])
          end

          # Total ticket entries closed
          @total_ticket_entries_closed_data = Dispute.ticket_entries_closed_by_day_report(current_user.my_team, params[:startdate], params[:enddate])
          @total_ticket_entries_closed_data[:report_labels].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @total_ticket_entries_closed_data[:report_w_data][i]
            final_row << @total_ticket_entries_closed_data[:report_e_data][i]
            final_row << @total_ticket_entries_closed_data[:report_ew_data][i]
            final_row << @total_ticket_entries_closed_data[:report_total_data][i]
            insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:total_ticket_entries_closed])
          end

          # Tickets submitted by submitter type
          @ticket_submitted_by_submitter_type_data = Dispute.tickets_submitted_by_submitter_per_day(params[:startdate], params[:enddate])
          @ticket_submitted_by_submitter_type_data[:chart_labels].each_with_index do |row, i|
            final_row = []
            final_row << row
            final_row << @ticket_submitted_by_submitter_type_data[:customer_chart_data][i]
            final_row << @ticket_submitted_by_submitter_type_data[:guest_chart_data][i]
            insert_row_with_data(final_row, myteamtickets_xlsx, myteamtickets_workbook_names[:ticket_submitted_by_submitter_type])
          end

          # Closed email entries by Resolution
          closed_email_by_resolution_data = Dispute.closed_ticket_entries_by_resolution_report(current_user.my_team, params[:startdate], params[:enddate], "E")
          closed_email_by_resolution_data[:table_data].each do |d|
            data_values = [d[:resolution], d[:count]]
            insert_row_with_data(data_values, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_email_by_resolution])
          end

          # Closed Web entries by Resolution
          closed_web_by_resolution_data = Dispute.closed_ticket_entries_by_resolution_report(current_user.my_team, params[:startdate], params[:enddate], "W")
          closed_web_by_resolution_data[:table_data].each do |d|
            data_values = [d[:resolution], d[:count]]
            insert_row_with_data(data_values, myteamtickets_xlsx, myteamtickets_workbook_names[:closed_web_by_resolution])
          end

          # End data insertion

          myteamtickets_xlsx.worksheets.delete(myteamtickets_xlsx['Sheet1'])

          myteamtickets_xlsx.write(myteamtickets_file)
          myteamtickets_file.rewind
        end

        input_filenames = Dir.entries(@spreadsheet_directory).select {|f| !File.directory? f}
        if input_filenames.count > 1
          filename = "webrep_export-#{Time.now.utc.iso8601}.zip"
          temp_file = Tempfile.new(filename)

          begin
            Zip::OutputStream.open(temp_file) { |zos| }

            #Add files to the zip file as usual
            Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
              input_filenames.each do |filename|
                  zipfile.add(filename, File.join(@spreadsheet_directory, filename))
                end
            end

            #Read the binary data from the file
            zip_data = File.read(temp_file.path)

            #Send the data to the browser as an attachment
            #We do not send the file directly because it will
            #get deleted before rails actually starts sending it
            send_data(zip_data, :type => 'application/zip', :filename => filename)
          ensure
            #Close and delete the temp file
            temp_file.close
            temp_file.unlink

            #Delete all generated spreadsheets
            input_filenames.each do |file|
              File.delete(File.join(@spreadsheet_directory, file))
            end
          end

        elsif input_filenames.count == 1
          File.open((File.join(@spreadsheet_directory, input_filenames[0])), 'r') do |f|
            send_data f.read, :filename => input_filenames[0]
          end

          File.delete(File.join(@spreadsheet_directory, input_filenames[0]))
        end

        if params['alltickets'] == "true"
          # Not yet implemented
        end

        if params['customtickets'] == "true"
          # Not yet implemented
        end
        
      end
    end
  end

  def research
    @entries = DisputeEntry.research_results(research_params)
  end

  def tickets
  end
  
  # def advanced_search
  #   @dispute = Dispute.new
  # end
  #
  # def named_search
  # end
  #
  # def standard_search
  # end
  #
  # def contains_search
  # end

  def export
    @dispute = Dispute.find(params[:id])
    contents = CSV.generate do |csv|
      csv << [
          'Host',
          'WBRS',
          'WBRS Rule Hits',
          'WBRS Rules',
          'SBRS',
          'SBRS Rule Hits',
          'SBRS Rules',
          'XBRS History',
          'Crosslisted URLs',
          'VirusTotal Negatives',
          'VirusTotal Total',
          'RepTool Class',
          'Blacklist Status',
          'Blacklist Comment',
          'WL/BL',
          'Umbrella',
          'Referenced On',
          'Last Submitted'
      ]
      @dispute.dispute_entries.each do |entry|
        csv << [
            entry.hostlookup,
            entry.wbrs_score,
            entry.dispute_rule_hits.wbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.wbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.sbrs_score,
            entry.dispute_rule_hits.sbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.sbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.hostlookup && entry.find_xbrs[1]['data'].count,
            entry.wbrs_xlist.count,
            entry.virustotals_negatives_count,
            entry.virustotals.count,
            entry.classifications.first,
            entry.classifications.first && entry.blacklist.status,
            entry.classifications.first && entry.blacklist.metadata&.fetch('VRT', {})['comment'],
            entry.wbrs_list_type,
            entry.umbrellaresult,
            entry.referenced_tickets.count,
            entry.last_submitted.to_s,
        ]
      end
    end
    send_data contents
  end

  def export_selected_dispute_entry_rows
    @dispute_entries = DisputeEntry.where(id: params[:ids])
    contents = CSV.generate do |csv|
      csv << [
          'Host',
          'WBRS',
          'WBRS Rule Hits',
          'WBRS Rules',
          'SBRS',
          'SBRS Rule Hits',
          'SBRS Rules',
          'XBRS History',
          'Crosslisted URLs',
          'VirusTotal Negatives',
          'VirusTotal Total',
          'RepTool Class',
          'Blacklist Status',
          'Blacklist Comment',
          'WL/BL',
          'Umbrella',
          'Referenced On',
          'Last Submitted'
      ]
      @dispute_entries.each do |entry|
        csv << [
            entry.hostlookup,
            entry.wbrs_score,
            entry.dispute_rule_hits.wbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.wbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.sbrs_score,
            entry.dispute_rule_hits.sbrs_rule_hits.count,
            "\"#{entry.dispute_rule_hits.sbrs_rule_hits.map {|wbrs_hit| wbrs_hit.name}.join(', ')}\"",
            entry.hostlookup && entry.find_xbrs[1]['data'].count,
            entry.wbrs_xlist.count,
            entry.virustotals_negatives_count,
            entry.virustotals.count,
            entry.classifications.first,
            entry.classifications.first && entry.blacklist.status,
            entry.classifications.first && entry.blacklist.metadata&.fetch('VRT', {})['comment'],
            entry.wbrs_list_type,
            entry.umbrellaresult,
            entry.referenced_tickets.count,
            entry.last_submitted.to_s,
        ]
      end
    end
    send_data contents, filename: "export.csv"
  end

  def resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['report']['date_from'],
                                                  date_to: params['report']['date_to'],
                                                  period: params['report']['period'])
  end

  def export_per_resolution_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_resolution do |pr_report|
        csv << [ pr_report.date_from, pr_report.date_to, 'TOTAL', nil, pr_report.total ]
        pr_report.each_resolution do |resolution, percent, count|
          csv << [ pr_report.date_from, pr_report.date_to, resolution, percent, count ]
        end
      end
    end
    send_data contents
  end

  def export_per_engineer_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_engineer do |pe_report|
        csv << [ pe_report.date_from, pe_report.date_to, 'TOTAL', nil, pe_report.total ]
        pe_report.each_resolution do |engineer, percent, count|
          csv << [ pe_report.date_from, pe_report.date_to, engineer, percent, count ]
        end
      end
    end
    send_data contents
  end

  def export_per_customer_report
    @report = DisputeReport::ResolutionReport.new(date_from: params['date_from'],
                                                  date_to: params['date_to'],
                                                  period: params['period'])

    contents = CSV.generate do |csv|
      csv << [ 'Date From', 'Date To', 'Resolution', '%', 'Count' ]
      @report.each_per_customer do |pe_report|
        csv << [ pe_report.date_from, pe_report.date_to, 'TOTAL', nil, pe_report.total ]
        pe_report.each_resolution do |customer, percent, count|
          csv << [ pe_report.date_from, pe_report.date_to, customer.name, percent, count ]
        end
      end
    end
    send_data contents
  end

  def resolution_age_report
    @entries = DisputeEntry.from_age_report_params(age_report_params)
  end

  def export_resolution_age_report
    @entries = DisputeEntry.from_age_report_params(age_report_params)

    contents = CSV.generate do |csv|
      csv << [ 'When Resolved', 'Resolution', 'Engineer', 'Opened', 'Resolved', 'Time to Resolution' ]
      @entries.each do |entry|
        csv << [
            entry.case_resolved_at,
            entry.resolution,
            entry.cvs_username,
            entry.case_opened_at,
            entry.case_resolved_at,
            ApplicationRecord.humanize_secs(entry.case_resolved_at - entry.case_opened_at)
        ]
      end
    end
    send_data contents
  end

  def export_selected_dispute_rows
    @disputes = Dispute.where(id: params[:ids])

    contents = RubyXL::Workbook.new
    @worksheet = contents[0]

    def singlesheet_insert_row_with_data(data, format = nil)
      data_insertion_index = @worksheet.sheet_data.rows.count
      data.each_with_index do |new_data, i|
        @worksheet.add_cell(data_insertion_index, i, new_data)
        case format
        when "bold"
          @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
        when "h1"
          @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
          @worksheet.sheet_data[data_insertion_index][i].change_font_size(14)
        when "h2"
          @worksheet.sheet_data[data_insertion_index][i].change_font_bold(true)
          @worksheet.sheet_data[data_insertion_index][i].change_font_size(12)
        end
      end
    end

    dispute_headers = ['Priority',
                       'Case ID',
                       'Status',
                       'Entry Count',
                       'Owner',
                       'Customer Name',
                       'Customer Email',
                       'Customer Company',
                       'Company URL',
                       'Time Submitted',
                       'Age',
                       'Dispute Entry',
                       'Dispute Entry Status',
                       'Suggested Disposition',
                       'Category',
                       'WBRS Score',
                       'WBRS Total Rule Hits',
                       'SBRS Score',
                       'SBRS Total Rule Hits',
                       'Important?',
                       'Resolution',
                       'Last Email Date',
                       'Comment Count',
                       'Resolution Comments']
    singlesheet_insert_row_with_data(dispute_headers, "h1")

    @disputes.each do |dispute|
      dispute.dispute_entries.each do |dispute_entry|
        singlesheet_insert_row_with_data([ dispute_entry.dispute.priority,
                                           dispute_entry.dispute.case_id_str,
                                           dispute_entry.dispute.status,
                                           dispute_entry.dispute.dispute_entries.count,
                                           dispute_entry.dispute.user.cvs_username,
                                           dispute_entry.dispute.customer.name,
                                           dispute_entry.dispute.customer.email,
                                           dispute_entry.dispute.customer.company.name,
                                           dispute_entry.dispute.org_domain,
                                           dispute_entry.dispute.case_opened_at.strftime("%FT%T"),
                                           ApplicationRecord.humanize_secs(Time.now - dispute_entry.dispute.case_opened_at),
                                           dispute_entry.hostlookup,
                                           dispute_entry.status,
                                           dispute_entry.suggested_disposition,
                                           dispute_entry.primary_category,
                                           dispute_entry.wbrs_score,
                                           dispute_entry.dispute_rule_hits.wbrs_rule_hits.count,
                                           dispute_entry.sbrs_score,
                                           dispute_entry.dispute_rule_hits.sbrs_rule_hits.count,
                                           dispute_entry.is_important,
                                           dispute_entry.resolution,
                                           dispute_entry.latest_email_date,
                                           dispute_entry.dispute.dispute_comments.count,
                                           dispute_entry.resolution_comment ])
      end
    end

    send_data contents.stream.string, filename: "disputes_search_#{Time.now.utc.iso8601}.xlsx", disposition: 'attachment'

  end

  private

  def search_params
    params.fetch(:dispute, {}).permit(:search_type, :search_name)
  end

  def index_params
    params.fetch(:dispute, {}).permit(:customer_name, :customer_email, :customer_company_name,
                                      :status, :resolution, :subject,
                                      :value)
  end

  def age_report_params
    params.permit(:date_from, :date_to, :resolution, :engineer, :customer_id)
  end

  def research_params
    params.fetch(:search, {}).permit(:uri, :scope)
  end
end
