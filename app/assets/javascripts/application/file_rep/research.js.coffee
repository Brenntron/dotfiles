$ ->

########### GRAB SHA NEEDED FOR REPORTS ############
#  If html body is on the show page (do not call on other pages)
  if $('body').hasClass('escalations--file_rep--disputes-controller') && $('body').hasClass('show-action')
    # On the show page we can pull the sha from the FILE OVERVIEW section
    # This prepares all the remaining functions for data fetches / updates
    sha256_hash = $('#sha256_hash')[0].innerText
    window.research_data(sha256_hash)

# Update the research reports and the items in the db
window.refresh_research_data = (sha256_hash) ->
  sha256_hash = $('#sha256_hash')[0].innerText
  window.research_data(sha256_hash)
  window.update_file_rep_data()



# Resubmit file sha hash to all the analysis engines
# services: threatgrid reversinglab or seperately, sandbox
# space delimited
window.evaluate_file =  (services) ->
  sha256_hash = $('#sha256_hash')[0].innerText
  unless services == 'threatgrid'
    services = []
  this_api = 'true'
  magic = 'true'

  # Submitted via individual button
  if services == 'threatgrid'
    wrapper = $('#threatgrid-report-wrapper')
    tg_report_present = wrapper.find('.tg-data-present')[0]
    tg_report_missing = wrapper.find('.tg-data-missing')[0]
    tg_report_running = wrapper.find('.tg-report-run')[0]
    $(tg_report_present).hide()
    $(tg_report_missing).hide()
    # Clear residual data
    $(tg_report_present).find('.data-report-content').each ->
      $(this).empty()
    $(tg_report_running).show()
    $('#tg-loader').show()

  # Multiple submission checkboxes / buttons
  else

    $('#resubmit-to-resources input:checked').each ->
      service = $(this).attr('data-service')
      wrapper = $('#' + service + '-report-wrapper')
      console.log wrapper
      switch service
        when 'threatgrid'
          tg_report_present = wrapper.find('.tg-data-present')[0]
          tg_report_missing = wrapper.find('.tg-data-missing')[0]
          tg_report_running = wrapper.find('.tg-report-run')[0]
          $(tg_report_present).hide()
          $(tg_report_missing).hide()
          # Clear residual data
          $(tg_report_present).find('.data-report-content').each ->
            $(this).empty()
          $(tg_report_running).show()
          $('#tg-loader').show()
          services += service + ' '
        when 'reversinglab'
          # When this is enabled some of the html structure needs to be changed
          # The submit to RL and the loading information will need to be added
          rl_report_present = wrapper.find('.rl-data-present')[0]
          rl_report_missing = wrapper.find('.rl-data-missing')[0]
          rl_report_running = wrapper.find('.rl-report-run')[0]
          $(rl_report_present).hide()
          $(rl_report_missing).hide()
          # Clear residual data
          $(rl_report_present).find('.data-report-content').each ->
            $(this).empty()
          $(rl_report_running).show()
          $('#rl-loader').show()
          services += service + ' '
        when 'sandbox'
          sb_report_present = wrapper.find('.sb-data-present')[0]
          sb_report_missing = wrapper.find('.sb-data-missing')[0]
          sb_report_running = wrapper.find('.sb-report-run')[0]
          $(sb_report_present).hide()
          $(sb_report_missing).hide()
          # Clear residual data
          $(sb_report_present).find('.data-report-content').each ->
            $(this).empty()
          $(sb_report_running).show()
          $('#sb-loader').show()
          this_api = 'false'
          magic = 'false'
          # Sandbox hits a different api endpoint than TG and RL
          run_sample_in_sandbox()

  if this_api == 'true'
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/file_rep/disputes/submit_for_evaluation/"
      data: {sha256_hash: sha256_hash, service: services, refresh_magic: magic}
      success_reload: false
      success: (response) ->
        if services.includes('threatgrid')
          setTimeout get_threatgrid_data, 600000
#        Add later when RL api is enabled
#        else if services.includes('reversinglab')
#          setTimeout(get_reversinglabs_data(sha256_hash), 600000)
      error: (response) ->
        std_api_error( response, "Submission Error", reload: false)
    )





########### COMPILE RESEARCH REPORTS ############
# Grabs the initial data for all three reports / datasets
# Loads on page load
# Report functions defined immediately below
window.research_data = (sha256_hash) ->
  window.get_threatgrid_data(sha256_hash)
  window.get_reversinglabs_data(sha256_hash)
  window.get_run_status(sha256_hash)
  window.get_zoo_status(sha256_hash)
  window.get_enrichment_service(sha256_hash)


########### SAMPLE ZOO STATUS ############
window.get_zoo_status = (sha256_hash) ->
  # check SHA256 against Sample Zoo
  $('#zoo-loader').show()
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sample_zoo/" + sha256_hash
    success_reload: false
    success: (response) ->

      $('#zoo-loader').hide()
      zoo_present = $('.zoo-data-present').find('span')
      zoo_missing = $('.zoo-data-notfound').find('span')

      unless response.json.error?
        if response.json.in_zoo == true
          zoo_present.addClass('glyphicon glyphicon-ok')
        else
          zoo_missing.addClass('glyphicon glyphicon-remove')
      else
        $(zoo_present).show()
        $(zoo_missing).hide()

    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from the Sample Zoo", reload: false)
  )





########### THREATGRID REPORT ############
get_threat_data = window.get_threatgrid_data = () ->
  # Send sha to ThreatGrid, get data
  loader = $('#tg-loader')
  sha256_hash = $('#sha256_hash')[0].innerText
  tg_report_running = $('#threatgrid-report-wrapper').find('.tg-report-run')[0]
  loader.show()
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/"
    data: {sha256_hash: sha256_hash}
    success_reload: false
    success: (response) ->
      wrapper = $('#threatgrid-report-wrapper')
      report_present = wrapper.find('.tg-data-present')[0]
      report_missing = wrapper.find('.tg-data-missing')[0]

      if response.json.data.current_item_count > 0
        file_data = response.json.data.items[0].item
        { state, submitted_at, tags, analysis } = file_data

        # if TG has a fail state, don't show most of the stuff
        switch state
          when 'fail'
            $('#tg-run-status').html('<span class="tg-fail-status">Failure</span>')
            $('#tg-score').siblings().hide()
            $('#tg-tags').closest('div.row').nextAll().hide()
            $(tg_report_running).hide()
            $(report_present).show()
            $(report_missing).hide()

          when 'succ'
            loader.hide()
            $(tg_report_running).hide()
            $(report_present).show()
            $(report_missing).hide()

            # dbinebri: use moment.js to make date readable, convert string to Date object first for best practice
            tg_formatted_submitted_date = moment(new Date( submitted_at )).format('MMM D, YYYY h:mm A')

            # Load the top data
            $('#tg-submission-date').text(tg_formatted_submitted_date)
            $('#tg-tags').text( tags.join(', '))
            $('#tg-run-status').text (state)

            # Ensure the analysis property exists first, it will not if there is a TG fail state
            unless !file_data.hasOwnProperty('analysis')
              # Adding threat score
              $('#tg-score').text( analysis.threat_score)
              # Adding behaviors
              behaviors = ""
              $( analysis.behaviors ).each ->
                behaviors += '<tr>'
                behaviors += '<td>' + this.name + '</td><td>' + this.threat + '</td><td>' + this.title + '</td>'
                behaviors += '</tr>'
              $('#tg-behaviors').append('<tbody>' + behaviors + '</tbody>')

              # Adding full json report in case it's needed
              full_report = JSON.stringify(response.json, null, 2)
              $('#tg-full').text(full_report)

              # dbinebri: Convert the Threatgrid full_report to a downloadable file, add the Download button hyperlink
              tg_json_file = 'text/json; charset=utf-8,' + encodeURIComponent(full_report)
              tg_filename = 'threatgrid_' + moment(new Date()).format('MM_DD_YYYY') + '.json'
              tg_json_link = '<a href="data:' + tg_json_file + '" download="' + tg_filename + '"></a>'
              $('#download-tg-json').wrap tg_json_link

          when 'wait'
            $(report_missing).hide()
            $(report_present).hide()
            $(tg_report_running).show()
            loader.show()
            setTimeout get_threatgrid_data, 600000
      else
        $(report_present).hide()
        $(report_missing).show()
        loader.hide()
        $(tg_report_running).hide()

    error: (response) ->
      loader.hide()
      std_api_error(response, "There was a problem retrieving data from ThreatGrid", reload: false)
  )





########### REVERSING LABS REPORT ############
window.get_reversinglabs_data = (sha256_hash) ->
  #  Send sha to reversing labs, get data
  $('#rl-loader').show()
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/filerep/reversing_labs/" + sha256_hash
    success_reload: false
    success: (response) ->
      $('#rl-loader').hide()
      report_present = $('#reversing-labs-report-wrapper').find('.rl-data-present')[0]
      report_missing = $('#reversing-labs-report-wrapper').find('.rl-data-missing')[0]

      unless response.json.error?
        rl_data = response.json.rl.sample.xref
        scanner_count = ""
        result_count = ""

        $(report_present).show()
        $(report_missing).hide()

        all_scanner_results = rl_data.entries[0]
        scan_time = all_scanner_results.record_time
        scanner_count = all_scanner_results.scanners.length

        # dbinebri: use moment.js to make dates readable
        first_seen_date = moment(new Date(rl_data.first_seen)).format('MMM D, YYYY h:mm A')
        last_seen_date = moment(new Date(rl_data.last_seen)).format('MMM D, YYYY h:mm A')
        formatted_scan_time = moment(new Date(scan_time)).format('MMM D, YYYY h:mm A')

        $('#rl-first-seen-date').text(first_seen_date)
        $('#rl-most-recent-date').text(last_seen_date)


        # Cycle through the scanner results
        mal_results = []
        unk_results = []
        $(all_scanner_results.scanners).each ->
          if this.result == ""
            unk_results.push(this)
          else
            mal_results.push(this)

        result_count = mal_results.length
        $('#rl-scanner-results').text(result_count + '/' + scanner_count)

        # Add the malicious scans to top of table, create rows from each scanner result
        tbody = ""
        $(mal_results).each ->
          tbody += '<tr><td>' + this.name + '</td><td>' + formatted_scan_time + '</td><td class="scanner-mal">' + this.result + '</td></tr>'
        $(unk_results).each ->
          tbody += '<tr><td>' + this.name + '</td><td>' + formatted_scan_time + '</td><td class="scanner-unk">Not Detected</td></tr>'

        $('#rl-scanner-table').append(tbody)
      else
        $(report_present).hide()
        $(report_missing).show()

    error: (response) ->
      $('#rl-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Reversing Labs", reload: false)
  )



########### TALOS SANDBOX REPORT ############
# Sandbox report api, get full report (json) from runid returned from the sandbox call above
window.get_sandbox_report = (runid, sha256_hash) ->
  wrapper = $('#sandbox-report-wrapper')
  report_present = wrapper.find('.sb-data-present')[0]
  report_missing = wrapper.find('.sb-data-missing')[0]
  report_running = wrapper.find('.sb-report-run')[0]
  $(report_running).hide()

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sandbox_api/sandbox_report/" + runid + '/' + sha256_hash
    success_reload: false
    success: (response) ->
      sb_report = response.json.data
      $('#sb-loader').hide()
      $(report_present).show()
      $(report_missing).hide()

      # dbinebri: use moment.js to make date readable
      sb_formatted_run_date = moment(new Date(sb_report.date)).format('MMM D, YYYY h:mm A')

      $('#sb-run-date').text(sb_formatted_run_date)
      $('#sb-run-status').text(sb_report.status)
      $('#sb-score').text(sb_report.score)


      # Contacted ips and domains
      contacted_ips = ""
      contacted_domains = ""

      if sb_report.contact.ips.length > 0
        $(sb_report.contact.ips).each ->
          contacted_ips += this.ip + '<br/>'
        $('#sb-contacted-ips').append(contacted_ips)
      else
        $('#sb-contacted-ips').html('<span class="missing-data">No IPs contacted</span>')

      if sb_report.contact.domainnames.length > 0
        $(sb_report.contact.domainnames).each ->
          contacted_domains += this.domainname + '<br/>'
        $('#sb-contacted-domains').append(contacted_domains)
      else
        $('#sb-contacted-domains').html('<span class="missing-data">No domains contacted</span>')


      # Indicators of compromise (IOC's)
      iocs = sb_report.ioc
      unless iocs.length > 0
        $('#sb-ioc-col').append('<span class="missing-data">No IOCs detected</span>')
      else
        ioc_table = '<table class="data-report-table"><thead><tr><th>Name</th><th class="text-center">Alerts</th></tr></thead><tbody>'
        $(iocs).each ->
          ioc_table += '<tr><td>' + this.name + '</td><td class="text-center overdue">' + this.alerts.length + '</td></tr>'
        ioc_table += '</tbody></table>'
        $('#sb-ioc-col').append(ioc_table)


      # Dropped Files
      dropped_files = sb_report.dropped_files
      dropped_files_tables = ""
      file_table = ""
      unless dropped_files.length > 0
        $('#sb-dropped-files-col').html('<span class="missing-data">No dropped files</span>')
      else
        $(dropped_files).each ->
          file_table =
            '<table class="vertical-data-report-table">' +
              '<tr><th class="text-right">MD5</th><td class="code-wrap-col"><span class="code-snippet code-string-break">' + this.MD5 + '</span></td></tr>' +
              '<tr><th class="text-right">SHA1</th><td class="code-wrap-col"><span class="code-snippet code-string-break">' + this.SHA1 + '</span></td></tr>' +
              '<tr><th class="text-right">SHA256</th><td class="code-wrap-col"><span class="code-snippet code-string-break">' + this.SHA256 + '</span></td></tr>' +
              '<tr><th class="text-right">mime</th><td>' + this.mime + '</td></tr>' +
              '<tr><th class="text-right">path</th><td>' + this.path + '</td></tr>' +
              '<tr><th class="text-right">size</th><td>' + this.size + '</td></tr>' +
              '</table>'

          dropped_files_tables += file_table
        $('#sb-dropped-files-col').append(dropped_files_tables)


      # Processes
      processes = sb_report.processes
      processes_tables = ""
      process_table = ""
      unless processes.length > 0
        $('#sb-processes-col').html('<span class="missing-data">No processes</span>')
      else
        $(processes).each ->
          process_table =
            '<table class="vertical-data-report-table">' +
              '<tr><th class="text-right">MD5</th><td class="code-wrap-col"><span class="code-snippet code-string-break">' + this.md5 + '</span></td></tr>' +
              '<tr><th class="text-right">Name</th><td>' + this.name + '</td></tr>' +
              '<tr><th class="text-right">PID</th><td>' + this.pid + '</td></tr>'
          if this.pname?
            process_table += '<tr><th class="text-right">pname</th><td>' + this.pname + '</td></tr>'
          if this.ppid?
            process_table += '<tr><th class="text-right">PPID</th><td>' + this.ppid + '</td></tr>'
          process_table += '</table>'
          processes_tables += process_table
        $('#sb-processes-col').append(processes_tables)


      # Adding full json report in case it's needed
      full_report = JSON.stringify(response.json, null, 2)
      $('#sb-full').text(full_report)

      # Adding link to see sandbox html report
      html = $('#sb-report-html')
      html.attr('data-sha', sha256_hash)
      html.attr('data-runid', runid)
      html.attr('href', "/escalations/file_rep/sandbox-html-report?run_id=" + runid + "&sha256_hash=" + sha256_hash)
      $('#sb-report-html-download').attr('href', "/escalations/file_rep/sandbox-html-report.gzip?run_id=" + runid + "&sha256_hash=" + sha256_hash)


      # dbinebri: Convert the Talos Sandbox full_report to a downloadable file, add the Download button hyperlink
      # build a formatted date string to add into the filename for download
      sb_today = new Date()
      sb_formatted_day =
        String(sb_today.getMonth() + 1).padStart(2, '0') + '_' +
        String(sb_today.getDate()).padStart(2, '0') + '_' + sb_today.getFullYear()

      # create a downloadable file out of the json with the filename preset + date
      sb_json_file = 'text/json; charset=utf-8,' + encodeURIComponent(full_report)
      sb_filename = 'sandbox_' + sb_formatted_day + '.json'
      sb_json_link = '<a href="data:' + sb_json_file + '" download="' + sb_filename + '"></a>'
      $('#download-sb-json').wrap sb_json_link


    error: (response) ->
      $('#sb-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Talos Sandbox", reload: false)
  )


########### TALOS SANDBOX:: RUN SAMPLE & GET REPORT ############
# This function can be called if there is no report present
# (so the sample has not been run in the sandbox) but the sample
# does exist in the zoo and therefore CAN be run in the sandbox.

window.run_sample_in_sandbox = () ->
  sha256_hash = $('#sha256_hash')[0].innerText
  report_present = $('#sandbox-report-wrapper').find('.sb-data-present')[0]
  report_missing = $('#sandbox-report-wrapper').find('.sb-data-missing')[0]
  report_running = $('#sandbox-report-wrapper').find('.sb-report-run')[0]
  $(report_present).hide()
  $(report_missing).hide()
  # Clear residual data
  $(report_present).find('.data-report-content').each ->
    $(this).empty()
  $(report_running).show()
  $('#sb-loader').show()

  # Create a new run in the sandbox (assuming sample CAN be run in sandbox)
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sandbox_api/sandbox_run_sample/" + sha256_hash
    success_reload: false
    success: (response) ->
      # Wait 1 minute so the run status is getting a new status
      # and not the complete status of the last report
      setTimeout(get_run_status, 60000)
    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from Talos Sandbox", reload: false)
)


########### GET SANDBOX CURRENT RUN STATUS & MOST RECENT RUN ID ############
#### This is needed prior to getting full report & needed for checking a report status
get_run_status = window.get_run_status = (sha256_hash) ->
  # Sandbox - send file hash, show loader while fetching data
  $('#sb-loader').show()
  sha256_hash = $('#sha256_hash')[0].innerText
  report_running = $('#sandbox-report-wrapper').find('.sb-report-run')[0]
  report_present = $('#sandbox-report-wrapper').find('.sb-data-present')[0]
  report_missing = $('#sandbox-report-wrapper').find('.sb-data-missing')[0]

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sandbox_api/sandbox_latest_report/" + sha256_hash
    success_reload: false
    success: (response) ->
      unless response.json.success == false
        run_id = response.json.data.runid
        status = response.json.data.status

        # If report status is complete, send runid to get report
        if status == "Complete"
          clearInterval(get_run_status)
          window.get_sandbox_report(run_id, sha256_hash)
        else if status == "Error"
          clearInterval(get_run_status)
          $('#sb-loader').hide()
          $(report_missing).show()
          $('#sandbox-status-message').text('Error running sample. Report not generated.')
        else if status == "Unsupported File Type"
          clearInterval(get_run_status)
          $('#sb-loader').hide()
          $(report_missing).show()
          $('#sandbox-status-message').text('Unsupported file type. Report not generated.')
        else if status == "Cancelled"
          clearInterval(get_run_status)
          $('#sb-loader').hide()
          $(report_missing).show()
          $('#sandbox-status-message').text('Report was cancelled.')
        else if status == "Running" || "JoeBox Analysis Running" || "Reports Generating" || "Enqueued to Report Generation"
          $(report_running).show()

        setTimeout(get_run_status, 600000)

      else
        $('#sb-loader').hide()
        $(report_present).hide()
        $(report_missing).show()
        if $('#sample-zoo-status').attr('data-zoo-status') == 'YES'
          $('#sandbox-status-message').text('No report available')
          $('#sandbox-run-button').show()
        else
          $('#sandbox-status-message').text('Not in Talos Sample Zoo')
          $('#sandbox-run-button').hide()


    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from Talos Sandbox", reload: false)
  )


########### ENRICHMENT API REPORT ############
window.get_enrichment_service = (sha256_hash) ->
  std_msg_ajax(
    method: 'GET'
    data: {'query_item': sha256_hash, 'query_type':'sha'}
    url: '/escalations/api/v1/escalations/cloud_intel/enrichment_service/query/'
    success_reload: false
    success: (response) ->
      combined_tags = []

      #look for data in context_tags, email_context_tags and web_context_tags
      if response?.data?.context_tags.length > 0
        combined_tags = combined_tags.concat(response.data.context_tags)

      if response?.data?.email_context_tags.length > 0
        combined_tags = combined_tags.concat(response.data.email_context_tags)

      if response?.data?.web_context_tags.length > 0
        combined_tags = combined_tags.concat(response.data.web_context_tags)

      $(combined_tags).each (index, tag) ->

        if tag.mapped_taxonomy?.name[0].text?
          name = tag.mapped_taxonomy.name[0].text
        else name = ''

        if tag.mapped_taxonomy?.description[0].text?
          description = tag.mapped_taxonomy.description[0].text
        else description = ''

        wrapper = $("<div></div>")

        name_wrapper = $("<div><label class='data-report-label data-tts-filerep-name-label'>TTS Name</label><p class='data-tts-filerep-name'></p></div>")
        $(name_wrapper).find('.data-tts-filerep-name').text(name)

        description_wrapper = $("<div><label class='data-report-label data-tts-filerep-description-label'>TTS Description</label><p class='data-tts-filerep-description'></p></div>")
        $(description_wrapper).find('.data-tts-filerep-description').text(description)

        $(wrapper).append name_wrapper
        $(wrapper).append description_wrapper
        $('#enrich-file-rep').append(wrapper)

      if combined_tags.length == 0
        $('#enrich-file-rep').append("<div><div class='text-center missing-data'>No enrichment service data found.</div></div>")

    error: (response) ->
      std_msg_error('Error with Enrichment Service', ['There was an error.'])
  )

##### UPDATE FILE REP DATA #####
# Refresh items from the reports that we store in the db & save them
window.update_file_rep_data = () ->
  file_rep_id = $(".case-id-tag")[0].innerText
  # Hide current data
  sb_data_true = $($('.sb-data-present')[0]).hide()
  sb_data_false = $($('.sb-data-missing')[0]).hide()
  tg_data_true = $($('.tg-data-present')[0]).hide()
  tg_data_false = $($('.tg-data-missing')[0]).hide()
  rl_data_true = $($('.rl-data-present')[0]).hide()
  rl_data_false = $($('.rl-data-missing')[0]).hide()

  # Round and round it goes
  sync_button = $('#file-rep-sync-button')
  $(sync_button).addClass('syncing')

  # Updating the info for the db
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/update_file_rep_data"
    data: {id: file_rep_id}
    success_reload: false
    success: (response) ->
      $('#tg-loader').hide()
      $('#sb-loader').hide()
      $('#rl-loader').hide()
      $(sync_button).removeClass('syncing')
    error: (response) ->
      $('#tg-loader').hide()
      $('#sb-loader').hide()
      $('#rl-loader').hide()
      $(sync_button).removeClass('syncing')
      std_api_error(response, "There was a problem refreshing some research data", reload: false)
  )


$ ->
  # dbinebri: on page load - setting the collapsed + height state for both json reports
  $('#collapse_sb_json, #collapse_tg_json').toggleClass("in").css("height", "300px").attr("aria-expanded", "false")


  # dbinebri: refactoring this. this is checkbox toggle column visible + widths on Show Page, Research tab
  $('#data-show-sandbox-cb').click -> $('#sandbox-report-wrapper').toggle()
  $('#data-show-tg-cb').click -> $('#threatgrid-report-wrapper').toggle()
  $('#data-show-reversing-cb').click -> $('#reversing-labs-report-wrapper').toggle()

  wrapper_list = $('#sandbox-report-wrapper, #threatgrid-report-wrapper, #reversing-labs-report-wrapper')

  $('#data-show-sandbox-cb, #data-show-tg-cb, #data-show-reversing-cb').click ->
    if $('.dataset-cb:checked').length == 1
      $(wrapper_list).removeClass('col-sm-4 col-sm-6').addClass('col-sm-12')
    else if $('.dataset-cb:checked').length == 2
      $(wrapper_list).removeClass('col-sm-4 col-sm-12').addClass('col-sm-6')
    else if $('.dataset-cb:checked').length == 3
      $(wrapper_list).removeClass('col-sm-6 col-sm-12').addClass('col-sm-4')
