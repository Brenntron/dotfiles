$ ->

  if $('#webcat-csam-reports-index').length
    build_csam_reports_table()
    build_csam_report_dialogs()

    $(document).on 'click', '#webcat-csam-reports-index tbody tr', ->
      enable_report_buttons()

    $('#resend-csam-reports-button').click ->
      entries = []
      $('#webcat-csam-reports-index tr.selected').each ->
        entry_id = $(this).find('.report-entry-id-col').text()
        url = $(this).find('.entry-url-col').text()
        entry_data = {entry_id: entry_id, url: url}
        entries.push(entry_data)
      open_resubmit_report_dialog(entries)

    $('#email-csam-reports-button').click ->
      entries = []
      $('#webcat-csam-reports-index tr.selected').each ->
        entry_id = $(this).find('.report-entry-id-col').text()
        url = $(this).find('.entry-url-col').text()
        entry_data = {entry_id: entry_id, url: url}
        entries.push(entry_data)
      open_forward_report_dialog(entries)

    window.resubmit_csam_report = () ->
      $('#resend_csam_reports_table tbody tr').each ->
        entry_id = $(this).find('.report-entry-id-col').text()
        data = {complaint_entry_id: entry_id, force: true}
        $.ajax(
          url: '/escalations/api/v1/escalations/webcat/complaints/resubmit_abuse_report'
          data: data
          method: 'POST'
          headers: 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
          success: (response) ->
            console.log response
            $('#resend_csam_reports_table tbody').empty()
            $('#resend_csam_reports_dialog').dialog 'close'
            std_msg_success('Success', ['Report resent.'])
          error: (response) ->
            console.log response
            $('#resend_csam_reports_table tbody').empty()
            $('#resend_csam_reports_dialog').dialog 'close'
            std_msg_error('Error', ['Report was not able to be sent'])
        , this)


    window.forward_csam_report = () ->
      cc_email = $('#cc_email_address').val()
      $('#forward_csam_reports_table tbody tr').each ->
        entry_id = $(this).find('.report-entry-id-col').text()
        data = {complaint_entry_id: entry_id, cc: cc_email}
        $.ajax(
          url: '/escalations/api/v1/escalations/webcat/complaints/forward_report'
          data: data
          method: 'POST'
          headers: 'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
          success: (response) ->
            console.log response
            $('#forward_csam_reports_table tbody').empty()
            $('#forward_csam_reports_dialog').dialog 'close'
            std_msg_success('Success', ['Report emailed.'])
          error: (response) ->
            console.log response
            $('#forward_csam_reports_table tbody').empty()
            $('#forward_csam_reports_dialog').dialog 'close'
            std_msg_error('Error', ['Report was not able to be forwarded.'])
        , this)



build_csam_reports_table = () ->
  csam_table = $('#webcat-csam-reports-index').DataTable(
    select: true
    processing: true
    serverSide: true
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    pagingType: 'full_numbers'
    order: [7, 'desc']
    columnDefs: [
      {
        targets: [0, 8]
        orderable: false
        searcheable: false
        sortable: false
      }
    ]
    ajax:
      url: $('#webcat-scam-reports-index').data('source')
      error: () ->
        console.log 'There has been an error calling the backend data'
    columns: [
      {
        data: 'record_id'
        className: 'attention-flag-col'
        render: (data, type, full, meta) ->
          if full.report_id? && full.report_id != ''
            return ''
          else
            return '<span class="attention-flag"></span>'
      }
      {
        data: 'complaint_entry_id'
        className: 'report-entry-id-col'
      }
      {
        data: 'date_resolved'
      }
      {
        data: 'url'
        className: 'entry-url-col'
      }
      {
        data: 'analyst'
      }
      {
        data: 'source'
      }
      {
        data: 'report_id'
        className: 'csam-report-id-col'
        render: (data, type, full, meta) ->
          if full.report_id? && full.report_id != ''
            return '<span class="report-id-wrapper" data-record-id="' + full.record_id + '" data-report-id="' + full.report_id + '" data-report-source="' + full.source + '">' + full.report_id + '</span>'
          else
            return ''
      }
      {
        data: 'date_sent'
      }
      {
        data: 'record_id'
        className: 'tools-col'
        render: (data, type, full, meta) ->

          buttons =
            '<button id="resend_csam_report_' + data + '" class="toolbar-button toolbar-button-spacer icon-reports esc-tooltipped resend-csam-report" title="Resend report" data-entry-id="' + full.complaint_entry_id + '" data-url="' + full.url + '"></button>' +
            '<button id="forward_csam_report_' + data + '" class="toolbar-button icon-email esc-tooltipped forward-csam-report" title="Forward report to external email address" data-entry-id="' + full.complaint_entry_id + '" data-url="' + full.url + '"></button>'
          return buttons
      }
    ]

    initComplete: ->
      # this need to be initialized after the dt is built
      $('#webcat-csam-reports-index_filter input').addClass('table-search-input')

    drawCallback: () ->
      # call whenever table is drawn
      $('.report-id-wrapper').click ->
        source = $(this).attr('data-report-source')
        record_id = $(this).attr('data-record-id')
        open_csam_report(record_id, source)

      $('#webcat-csam-reports-index .esc-tooltipped').tooltipster
        theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
        debug: false

      $('.resend-csam-report').click ->
        entry_id = $(this).attr('data-entry-id')
        url = $(this).attr('data-url')
        entry_data = {entry_id: entry_id, url: url}
        open_resubmit_report_dialog([entry_data])

      $('.forward-csam-report').click ->
        entry_id = $(this).attr('data-entry-id')
        url = $(this).attr('data-url')
        entry_data = {entry_id: entry_id, url: url}
        open_forward_report_dialog([entry_data])
  )


enable_report_buttons = () ->
  if $('tr.selected').length >= 1
    $('.csam-reports-toolbar button').removeAttr('disabled')
  else
    $('.csam-reports-toolbar button').attr('disabled', 'disabled')


build_csam_report_dialogs = () ->
  $('.csam-report-dialog').each ->
    $(this).dialog
      autoOpen: false
      minWidth: 600
      resizable: true

open_csam_report = (record_id, report_type) ->
  dialog_id = "##{report_type}_report_dialog_#{record_id}"
  $(dialog_id).dialog('open')


# works for individual or bulk re-submits
open_resubmit_report_dialog = (entries) ->
  $('#resend_csam_reports_table tbody').empty()
  $(entries).each ->
    entry_id = this.entry_id
    url = this.url
    dialog_table_row = "<tr><td class='report-entry-id-col'>#{entry_id}</td><td class='entry-url-col'>#{url}</td></tr>"
    $('#resend_csam_reports_table').append(dialog_table_row)

  $('#resend_csam_reports_dialog').dialog 'open'


open_forward_report_dialog = (entries) ->
  $('#forward_csam_reports_table tbody').empty()
  $(entries).each ->
    entry_id = this.entry_id
    url = this.url
    dialog_table_row = "<tr><td class='report-entry-id-col'>#{entry_id}</td><td class='entry-url-col'>#{url}</td></tr>"
    $('#forward_csam_reports_table').append(dialog_table_row)

  $('#forward_csam_reports_dialog').dialog 'open'


