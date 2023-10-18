#### WBNP Reporting ####
### DO NOT BREAK UP WBNP FUNTIONS ###
webcat_loader_timeout = ''
$ ->

  loader = $('#inline-webcat')
  $(this).bind(
    ajaxStart: () ->
      webcat_loader_timeout = setTimeout ->
        loader.removeClass('hidden')
      , 500
    ajaxStop: () ->
      clearTimeout(webcat_loader_timeout)
      loader.addClass('hidden')
  )

  page = $('body')
  if (page).hasClass('escalations--webcat--complaints-controller') || $(page).hasClass('escalations--webcat--reports-controller') && $(page).hasClass('index-action')
    check_wbnp_status()



# WBNP - Get report id
window.fetch_wbnp_data = () ->
  $('#fetch_wbnp').attr('disabled', true)
  $('#fetch_wbnp').addClass('esc-tooltipped')
  $('.wbnp-loading-spinner').show()
  # Set status on header to checking
  top_status = $('.top-area-bar').find('.wbnp-report-status')[0]
  $(top_status).text('Checking...')

  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/fetch_wbnp_data'
    data: {}
    success: (response) ->
      json = $.parseJSON(response)
      wbnp_report_id = json.wbnp_report_id
      check_wbnp_status(wbnp_report_id)

    error: (response) ->
      std_api_error(response, 'Error fetching wbnp data complaints.', reload: false)
  )


# WBNP - Check report info
check_wbnp = window.check_wbnp_status = (wbnp_report_id) ->
  if $('#wbnp-full-report').length > 0
    # this is a webcat manager and they get the full WBNP report
    data = {}
    full_report = true
    # Turn on the checking message if needed
    unless $('#current-wbnp-report .wbnp-status').hasClass('status_complete')
      wbnp_check = $('.wbnp-full-report-title-status')[0]
      $(wbnp_check).addClass('active')
      wbnp_status = 'Checking report status...'
      $(wbnp_check).text(wbnp_status)

  else
    data = {wbnp_report_id: wbnp_report_id}
    full_report = false

  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/complaints/wbnp_report_status"
    data: data
    success: (response) ->
      $('.wbnp-loading-spinner').hide()
      # Turn off loader indicator
      if full_report == true
        # Clear old data
        $('.wbnp-status').empty();
        $('.wbnp-status-msg').empty();
        $('.wbnp-full-report-table tbody').empty();
        $('.wbnp-notes').empty();

        curr_report = response.data[0]
        last_report = response.data[1]
        currentSkippedText = if curr_report.cases_skipped? then curr_report.cases_skipped else '0'

        # Add current report info to top bar report area

        $('.wbnp-report-status').text(curr_report.status)
        $('#wbnp-report-attempted').text(curr_report.total_new_cases)
        $('#wbnp-report-succeeded').text(curr_report.cases_imported)
        $('#wbnp-report-rejected').text(curr_report.cases_failed)
        $('#wbnp-quick-report-skipped').text(currentSkippedText)
        $('#wbnp-full-report-skipped').text(currentSkippedText)

        # Build the full report for webcat managers
        wbnp_dialog = $('#wbnp-full-report')

        # Current report:
        if curr_report.status == 'complete'
          $('#current-wbnp-report .wbnp-status').addClass('status_complete')
        else
          $('#current-wbnp-report .wbnp-status').removeClass('status_complete')
        $('#current-wbnp-report .wbnp-status').text(curr_report.status)
        $('#current-wbnp-report .wbnp-status-msg').text(curr_report.status_message)
        current_table = $('#current-wbnp-report .wbnp-full-report-table')
        curr_table_content = '<tr><td>' + curr_report.id + '</td><td>' + curr_report.attempts + '</td><td>' + curr_report.total_new_cases + '</td><td>' + curr_report.cases_imported + '</td><td>' + curr_report.cases_failed + '</td><td>' + currentSkippedText + '</td><td>' + curr_report.created_at + '</td><td>' + curr_report.updated_at + '</td></tr>'
        $(current_table).append(curr_table_content)
        $('#current-wbnp-report .wbnp-notes').html(curr_report.notes)

        # Previous report:
        if last_report?
          lastSkippedText = if last_report.cases_skipped? then last_report.cases_skipped else '0'
          if last_report.status == 'complete'
            $('#previous-wbnp-report .wbnp-status').addClass('status_complete')
          else
            $('#previous-wbnp-report .wbnp-status').removeClass('status_complete')
          $('#previous-wbnp-report .wbnp-status').text(last_report.status)
          $('#previous-wbnp-report .wbnp-status-msg').text(last_report.status_message)
          prev_table = $('#previous-wbnp-report .wbnp-full-report-table')
          prev_table_content = '<tr><td>' + last_report.id + '</td><td>' + last_report.attempts + '</td><td>' + last_report.total_new_cases + '</td><td>' + last_report.cases_imported + '</td><td>' + last_report.cases_failed + '</td><td>' + lastSkippedText + '</td><td>' + last_report.created_at + '</td><td>' + last_report.updated_at + '</td></tr>'
          $(prev_table).append(prev_table_content)
          $('#previous-wbnp-report .wbnp-notes').html(last_report.notes)

        # Keep checking / updating if Current report is unfinished
        if curr_report.status != 'complete'
          if $('.wbnp-full-report-title-status').length == 0
            $('.ui-dialog .ui-dialog-title').append('<span class="wbnp-full-report-title-status"></span>')
          wbnp_check = $('.wbnp-full-report-title-status')[0]
          wbnp_status = 'Checking report status in 45 seconds...'
          $(wbnp_check).removeClass('active')
          $(wbnp_check).text(wbnp_status)
          setTimeout(check_wbnp, 45000)
        else
          $('.wbnp-full-report-title-status').remove()

      else
        curr_report = response.data[0]
        currentSkippedText = if curr_report.cases_skipped? then curr_report.cases_skipped else '0'
        # Add current report info to top bar report area
        $('.wbnp-report-status').text(curr_report.status)
        $('#wbnp-report-attempted').text(curr_report.total_new_cases)
        $('#wbnp-report-succeeded').text(curr_report.cases_imported)
        $('#wbnp-report-rejected').text(curr_report.cases_failed)
        $('#wbnp-quick-report-skipped').text(currentSkippedText)
        $('#wbnp-full-report-skipped').text(currentSkippedText)

    error: (response) ->
      $('.wbnp-loading-spinner').hide()

      std_msg_error("Unable to pull wbnp status", [], reload: false)
  )
