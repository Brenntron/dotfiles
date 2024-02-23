$ ->
  build_csam_reports_table()
  build_csam_report_dialogs()

  $(document).on 'click', '#webcat-csam-reports-index tbody tr', ->
    enable_report_buttons()

  $('.ncmec-report-id').click ->
    unless $(this).attr('data-ncmec-id')?
      return
    report_id = $(this).attr('data-ncmec-id')
    open_csam_report(report_id, 'ncmec')

  $('.iwf-report-id').click ->
    report_id = $(this).attr('data-iwf-id')
    open_csam_report(report_id, 'iwf')





build_csam_reports_table = () ->
  csam_table = $('#webcat-csam-reports-index').DataTable(
    stateSave: true
    select: true
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
    language: {
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }

    initComplete: ->
      $('#webcat-csam-reports-index_filter input').addClass('table-search-input')
  )


enable_report_buttons = () ->
  if $('tr.selected').length >= 1
    $('#send-to-ncmec-button').removeAttr('disabled')
    $('#send-to-iwf-button').removeAttr('disabled')
  else
    $('#send-to-ncmec-button').attr('disabled', 'disabled')
    $('#send-to-iwf-button').attr('disabled', 'disabled')


build_csam_report_dialogs = () ->
  $('.csam-report-dialog').each ->
    $(this).dialog
      autoOpen: false
      minWidth: 500

open_csam_report = (report_id, report_type) ->
  dialog_id = "##{report_type}_report_dialog_#{report_id}"
  $(dialog_id).dialog('open')



submit_ncmec_report = () ->
  debugger

submit_iwf_report = () ->
  debugger

