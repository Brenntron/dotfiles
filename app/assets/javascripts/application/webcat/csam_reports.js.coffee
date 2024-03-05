$ ->

  if $('#webcat-csam-reports-index').length
    build_csam_reports_table()
    build_csam_report_dialogs()

    $(document).on 'click', '#webcat-csam-reports-index tbody tr', ->
      enable_report_buttons()





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
      }
      {
        targets: [0]
        className: 'attention-flag-col'
      }
      {
        targets: [8]
        className: 'tools-col'
      }
    ]
    ajax:
      url: $('#webcat-scam-reports-index').data('source')
      error: () ->
        console.log 'There has been an error calling the backend data'
    columns: [
      {
        data: 'record_id'
        render: (data, type, full, meta) ->
          if full.report_id? && full.report_id != ''
            return ''
          else
            return '<span class="attention-flag"></span>'
      }
      {
        data: 'complaint_entry_id'
      }
      {
        data: 'date_resolved'
      }
      {
        data: 'url'
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
        render: (data) ->
         return '<button id="resend_csam_report_' + data + '" class="toolbar-button toolbar-button-spacer icon-reports esc-tooltipped" title="Resend report"</button><button id="forward_csam_report_' + data + '" class="toolbar-button icon-email esc-tooltipped" title="Forward report to external email address"</button>'
      }
    ]

    initComplete: ->
      $('#webcat-csam-reports-index_filter input').addClass('table-search-input')
      $('.report-id-wrapper').click ->
        source = $(this).attr('data-report-source')
        record_id = $(this).attr('data-record-id')
        open_csam_report(record_id, source)
      $('#webcat-csam-reports-index .esc-tooltipped').tooltipster
        theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
        debug: false
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
      minWidth: 500

open_csam_report = (record_id, report_type) ->
  dialog_id = "##{report_type}_report_dialog_#{record_id}"
  $(dialog_id).dialog('open')



resubmit_report = (report_id) ->
  debugger


forward_report = (report_id) ->
  debugger



