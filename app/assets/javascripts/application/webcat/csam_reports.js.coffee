$ ->

  if $('#webcat-csam-reports-index').length
    build_csam_reports_table()
    build_csam_report_dialogs()

    $(document).on 'click', '#webcat-csam-reports-index tbody tr', ->
      enable_report_buttons()

    $('.csam-report-id-col').click ->
      source = $(this).attr('data-report-source')
      report_id = $(this).attr('data-report-id')
      open_csam_report(report_id, source)





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
    order: [ 6, 'desc']
    columnDefs: [
      targets: [0, 8]
      orderable: false
      searcheable: false
    ]
    ajax:
      url: $('#webcat-scam-reports-index').data('source')
      error: () ->
        console.log 'There has been an error calling the backend data'
    columns: [
      {
        data: 'record_id'
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
      }
      {
        data: 'date_sent'
      }
      {
        data: 'report_id'
        render: (data) ->
         return "<button class='toolbar-button toolbar-button-spacer icon-reports esc-tooltipped' title='Resend report'</button><button class='toolbar-button icon-email esc-tooltipped' title='Forward report to external email address'</button>"
      }
    ]

    initComplete: ->
      $('#webcat-csam-reports-index_filter input').addClass('table-search-input')
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

open_csam_report = (report_id, report_type) ->
  dialog_id = "##{report_type}_report_dialog_#{report_id}"
  $(dialog_id).dialog('open')



resubmit_report = (report_id) ->
  debugger


forward_report = (report_id) ->
  debugger



