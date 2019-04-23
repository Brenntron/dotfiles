$ ->
#  If html body is on the show page
  if $('body').hasClass('show-action')
    window.research_data()


window.research_data = () ->
  sha256_hash = $('#sha256_hash')[0].innerText

  # Send sha to ThreatGrid, get data
  $('#tg-loader').show()
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/"
    data: {sha256_hash: sha256_hash}
    success_reload: false
    success: (response) ->
      $('#tg-loader').hide()
      report_present = $('#threatgrid-report-wrapper').find('.tg-data-present')[0]
      report_missing = $('#threatgrid-report-wrapper').find('.tg-data-missing')[0]

      if response.json.data.current_item_count > 0
        $(report_present).show()
        $(report_missing).hide()
        file_data = response.json.data.items[0].item

        # dbinebri: use moment.js to make date readable
        tg_formatted_submitted_date = moment(file_data.submitted_at).format('MMM D, YYYY h:mm A');

      # Load the top data
        $('#tg-submission-date').text(tg_formatted_submitted_date)
        $('#tg-run-status').text(file_data.state)
        $('#tg-score').text(file_data.analysis.threat_score)
        $('#tg-tags').text(file_data.tags.join(', '))

        # Adding behaviors
        behaviors = ""
        $(file_data.analysis.behaviors).each ->
          behaviors += '<tr>'
          behaviors += '<td>' + this.name + '</td><td>' + this.threat + '</td><td>' + this.title + '</td>'
          behaviors += '</tr>'
        $('#tg-behaviors').append('<tbody>' + behaviors + '</tbody>')

        # Adding full json report in case it's needed
        full_report = JSON.stringify(response.json, null, '\t')
        $('#tg-full').text(full_report)

      else
        $(report_present).hide()
        $(report_missing).show()
#        TODO Set up ability to push to ThreatGrid if sample does not come back

    error: (response) ->
      $('#tg-loader').hide()
      std_api_error(response, "There was a problem retrieving data from ThreatGrid", reload: false)
  )



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

        # dbinebri: use moment.js to make date readable
        rl_first_seen_date = moment(rl_data.first_seen).format('MMM D, YYYY h:mm A');
        rl_last_seen_date = moment(rl_data.last_seen).format('MMM D, YYYY h:mm A');

        $('#rl-first-seen-date').text(rl_first_seen_date)
        $('#rl-most-recent-date').text(rl_last_seen_date)


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
          tbody += '<tr><td>' + this.name + '</td><td>' + scan_time + '</td><td class="scanner-mal">' + this.result + '</td></tr>'
        $(unk_results).each ->
          tbody += '<tr><td>' + this.name + '</td><td>' + scan_time + '</td><td class="scanner-unk">Not Detected</td></tr>'

        $('#rl-scanner-table').append(tbody)
      else
        $(report_present).hide()
        $(report_missing).show()

    error: (response) ->
      $('#rl-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Reversing Labs", reload: false)
  )



  # Sandbox - get runid from file hash
  $('#sb-loader').show()
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sandbox_api/sandbox_latest_report/" + sha256_hash
    success_reload: false
    success: (response) ->
      report_present = $('#sandbox-report-wrapper').find('.sb-data-present')[0]
      report_missing = $('#sandbox-report-wrapper').find('.sb-data-missing')[0]
      run_id = response.json.data.runid

      # This sha has not been run in the talos sandbox
      unless run_id?
        $('#sb-loader').hide()
        $(report_present).hide()
        $(report_missing).show()
        if $('#sample-zoo-status').attr('data-zoo-status') == 'YES'
          $('#sandbox-status-message').text('Not in Talos Sandbox')
          $('#sandbox-run-button').show()
        else
          $('#sandbox-status-message').text('Not in Talos Sandbox or Sample Zoo')
          $('#sandbox-run-button').hide()
      else
        # Send runid to sandbox
        window.get_sandbox_report(run_id, sha256_hash)

    error: (response) ->
      $('#sb-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Talos Sandbox", reload: false)
  )


# Sandbox report api, get full report (json) from runid returned from the sandbox
window.get_sandbox_report = (runid, sha) ->
  report_present = $('#sandbox-report-wrapper').find('.sb-data-present')[0]
  report_missing = $('#sandbox-report-wrapper').find('.sb-data-missing')[0]

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/file_rep/sandbox_api/sandbox_report/" + runid + '/' + sha
    success_reload: false
    success: (response) ->
      sb_report = response.json.data
      $('#sb-loader').hide()
      $(report_present).show()
      $(report_missing).hide()

      # dbinebri: use moment.js to make date readable
      sb_formatted_run_date = moment(sb_report.date).format('MMM D, YYYY h:mm A');

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
      full_report = JSON.stringify(response.json, null, '\t')
      $('#sb-full').text(full_report)

    error: (response) ->
      $('#sb-loader').hide()
      std_api_error(response, "There was a problem retrieving data from Talos Sandbox", reload: false)
  )
