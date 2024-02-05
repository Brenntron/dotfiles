$ ->

########### GRAB SHA NEEDED FOR REPORTS ############
#  If html body is on the show page (do not call on other pages)
  if $('body').hasClass('escalations--file_rep--disputes-controller') && $('body').hasClass('show-action')
    # On the show page we can pull the sha from the FILE OVERVIEW section
    # This prepares all the remaining functions for data fetches / updates
    sha256_hash = $('#sha256_hash')[0].innerText
    window.research_data(sha256_hash)

# load the local RL api data the first time page loads:
$(document).on 'ready',->
  window.get_local_reversinglabs_api()


# Update the research reports and the items in the db
window.refresh_research_data = (sha256_hash) ->
  sha256_hash = $('#sha256_hash')[0].innerText
  window.research_data(sha256_hash)
  window.get_local_reversinglabs_api()
  window.update_file_rep_data()



# Resubmit file sha hash to all the analysis engines
# services: threatgrid, reversinglab
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
  window.get_zoo_status(sha256_hash)
  window.enrich_ajax_filerep(sha256_hash)


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

########### REVERSING LABS LOCAL API ############
window.get_local_reversinglabs_api = () ->
  file_rep_id = $(".case-id-tag")[0].innerText

  threat_name = $("#local-rl-threat-name")
  threat_status = $("#local-rl-threat-status")
  threat_scan = $("#local-rl-threat-scan")
  threat_signer = $("#local-rl-signer")

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/filerep/research/local_reversinglabs_api"
    data: {id: file_rep_id}
    success_reload: false
    success: (response) ->
      name = response['threat_name']
      status = response['threat_status']
      scan = response['last_scan_date']
      signer = response['digital_signer']

      if not name?
        name = "N/A"
      if not status?
        status = "N/A"
      if not scan?
        scan = "N/A"
      if not signer?
        signer = "N/A"

      # format date:
      scan_date = moment(new Date(scan)).format('MMM D, YYYY h:mm A')

      # add data from response to page:
      threat_name.text(name)
      threat_status.text(status)
      threat_scan.text(scan_date)
      threat_signer.text(signer)

    error: (response) ->
      std_api_error(response, "There was a problem retrieving data from the local Reversing Labs api", reload: false)
  )  


$ ->
  # on page load - setting the collapsed + height state for both json reports
  $('#collapse_sb_json, #collapse_tg_json').toggleClass("in").css("height", "300px").attr("aria-expanded", "false")

  # checkbox toggle column visible + widths on Show Page, Research tab
  $('#data-show-tg-cb').click -> $('#threatgrid-report-wrapper').toggle()
  $('#data-show-reversing-cb').click -> $('#reversing-labs-report-wrapper').toggle()

  wrapper_list = $('#threatgrid-report-wrapper, #reversing-labs-report-wrapper')

  $('#data-show-tg-cb, #data-show-reversing-cb').click ->
    if $('.dataset-cb:checked').length == 1
      $(wrapper_list).removeClass('col-sm-6').addClass('col-sm-12')
    else if $('.dataset-cb:checked').length == 2
      $(wrapper_list).removeClass('col-sm-12').addClass('col-sm-6')
