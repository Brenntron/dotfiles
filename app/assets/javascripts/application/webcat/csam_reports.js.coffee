$ ->
  if $('#webcat-csam-reports-index').length
    build_csam_reports_table()
    build_csam_report_dialogs()

    $(document).on 'click', '#webcat-csam-reports-index tbody tr', ->
      enable_report_buttons()

    $('#resend-csam-reports-button').click ->
      entries = []
      $('#webcat-csam-reports-index tr.selected').each ->
        $this = $(this)
        entry_id = $this.find('.report-entry-id-col').text()

        return true if entries.some((entry) -> entry.entry_id == entry_id)

        url = $this.find('.entry-url-col').text()
        entry_data = { entry_id: entry_id, url: url }

        entries.push(entry_data)
      open_resubmit_report_dialog(entries)

    $('#email-csam-reports-button').click ->
      entries = []
      processed_rows = []

      # Get all of the reports for each Complaint Entry, even if some reports are not selected
      # All reports for a Complaint Entry are forwarded and a CE is resubmitted to both NCMEC and IWF
      # as long as a single row for the entry is selected.
      $('#webcat-csam-reports-index tr.selected').each ->
        rows = []
        $this = $(this)
        entry_id = $this.data('entry-id')

        return true if processed_rows.includes(entry_id)

        entry_rows = $("tr[data-entry-id='#{entry_id}']")

        entry_rows.each ->
          $entry_row = $(this)
          url = $entry_row.find('.entry-url-col').text()
          entry_data = { entry_id: entry_id, url: url }
          report_el = $entry_row.find("span[data-entry-id='#{entry_id}']")
          report_id = if report_el.length
                        report_el.data('report-id')
                      else
                        'No Report'
          source = $entry_row.find('.source-col')[0].innerText
          entry_data['source'] = source
          entry_data['report_id'] = report_id

          entries.push(entry_data)
          processed_rows.push(entry_id)
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
      $cc_email_input = $('#cc_email_address')
      cc_email = $cc_email_input.val()

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
            $cc_email_input.val('')
            $('#forward_csam_reports_dialog').dialog 'close'
            std_msg_success('Success', ['Report emailed.'])
          error: (response) ->
            console.log response
            $('#forward_csam_reports_table tbody').empty()
            $cc_email_input.val('')
            $('#forward_csam_reports_dialog').dialog 'close'
            std_msg_error('Error', ['Report was not able to be forwarded.'])
        , this)



build_csam_reports_table = () ->
  entries_per_page = localStorage.getItem('csam_entries_per_page') || 10

  csam_table = $('#webcat-csam-reports-index').DataTable(
    select: true
    pageLength: entries_per_page
    processing: true
    serverSide: true
    dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>rt<ip>'
    language: {
      processing: "<div class='loader-container'><div class='loader-gears'><!-- Generator: Adobe Illustrator 22.0.0, SVG Export Plug-In . SVG Version: 6.00 Build 0)  --><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' id='Layer_1' x='0px' y='0px' viewBox='0 0 20 20' style='enable-background:new 0 0 20 20;' xml:space='preserve'><style type='text/css'>	.gear_one{fill:#BABABA;} .bounding_box{fill:none;} .gear_two:#4D4D4D;}</style><g id='gear_larger' class='rotating'> <path class='gear_one' d='M7.9,11.5c0,0.7-0.5,1.1-1.1,1.1s-1.1-0.5-1.1-1.1c0-0.7,0.5-1.1,1.1-1.1S7.9,10.8,7.9,11.5z M12.3,11l-0.2-1   l-1.5-0.3L10.1,9l0.6-1.4L10,6.9L8.6,7.8L7.8,7.4L7.3,5.9h-1L5.7,7.4L4.9,7.8L3.6,6.9L2.9,7.6L3.5,9L3,9.8l-1.5,0.3l-0.2,1l1.3,0.8   l0.2,0.9l-1,1.1l0.4,1l1.5-0.3L4.4,15v1.5l1,0.4l1-1.1h0.9l1,1.1l1-0.4V15l0.7-0.6l1.5,0.3l0.5-0.9l-1-1.1l0.2-0.9L12.3,11z'></path>	<rect x='1.3' y='5.9' class='bounding_box' width='11' height='11'></rect></g><g id='gear_smaller' class='rotating'> <path class='gear_two' d='M13.8,7c0-0.5,0.4-0.9,0.9-0.9s0.9,0.4,0.9,0.9s-0.4,0.9-0.9,0.9C14.2,7.8,13.8,7.4,13.8,7z M17.3,6.6l1-1.1   l-0.5-0.9l-1.4,0.3l-0.6-0.4l-0.5-1.4h-1.1l-0.5,1.4L13,4.9l-1.4-0.3l-0.5,0.9l1,1.1v0.7l-1,1.1l0.5,0.9L13,9l0.6,0.4l0.5,1.4h1.1   l0.5-1.4L16.3,9l1.4,0.3l0.5-0.9l-1-1.1V6.6H17.3z'></path> <rect x='10.7' y='2.9' class='bounding_box' width='8' height='8'></rect></g></svg></div><p class='loader-msg'>Loading Data...</p></div>"
      search: "_INPUT_"
      searchPlaceholder: "Search within table"
    }
    pagingType: 'full_numbers'
    order: [7, 'desc']
    columnDefs: [
      {
        targets: [0, 8]
        orderable: false
        searchable: false
        sortable: false
      }
    ]
    ajax:
      url: $('#webcat-scam-reports-index').data('source')
      complete: () ->
        # set listener for table length changes and save to localstorage
        $('#webcat-csam-reports-index').DataTable().on('length.dt', (e, settings, len) ->
          localStorage.setItem 'csam_entries_per_page', len
        )
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
        className: 'source-col'
      }
      {
        data: 'report_id'
        className: 'csam-report-id-col'
        render: (data, type, full, meta) ->
          if full.report_id? && full.report_id != ''
            return """
                <span
                  class="report-id-wrapper"
                  data-entry-id="#{full.complaint_entry_id}"
                  data-record-id="#{full.record_id}"
                  data-report-id="#{full.report_id}"
                  data-report-source="#{full.source}">
                    #{full.report_id}
                </span>
              """
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

          buttons = """
            <button
              id="resend_csam_report_#{data}"
              class="toolbar-button toolbar-button-spacer icon-reports esc-tooltipped resend-csam-report"
              title="Resend report"
              data-entry-id="#{full.complaint_entry_id}"
              data-url="#{full.url}">
            </button>
            <button
              id="forward_csam_report_#{data}"
              class="toolbar-button icon-email esc-tooltipped forward-csam-report"
              title="Forward report to external email address"
              data-entry-id="#{full.complaint_entry_id}"
              data-url="#{full.url}">
            </button>
          """
          return buttons
      }
    ]

    initComplete: ->
      # this need to be initialized after the dt is built
      $('#webcat-csam-reports-index_filter input').addClass('table-search-input')

    createdRow: (row, data) ->
      $(row).attr('data-entry-id', data.complaint_entry_id)
    drawCallback: () ->
      # call whenever table is drawn
      $('.report-id-wrapper').click ->
        source = $(this).data('report-source')
        record_id = $(this).data('record-id')
        open_csam_report(record_id, source)

      $('#webcat-csam-reports-index .esc-tooltipped').tooltipster
        theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
        debug: false

      $('.resend-csam-report').click ->
        $this = $(this)
        entry_id = $this.data('entry-id')
        url = $this.data('url')
        entry_data = {
          entry_id: entry_id,
          url: url
        }

        open_resubmit_report_dialog([entry_data])

      $('.forward-csam-report').click ->
        entries = []
        $this = $(this)
        entry_id = $this.data('entry-id')
        url = $this.data('url')
        entry_rows = $("tr[data-entry-id='#{entry_id}']")

        entry_rows.each ->
          $entry_row = $(this)
          entry_data = { entry_id: entry_id, url: url }
          report_el = $entry_row.find("span[data-entry-id='#{entry_id}']")
          report_id = if report_el.length
                        report_el.data('report-id')
                      else
                        'No Report'
          source = $entry_row.find('.source-col')[0].innerText
          entry_data['source'] = source
          entry_data['report_id'] = report_id

          entries.push(entry_data)

        open_forward_report_dialog(entries)
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
    dialog_table_row = """
      <tr>
        <td class='report-entry-id-col'>
          #{this.entry_id}
        </td>
        <td class='entry-url-col'>
          #{this.url}
        </td>
      </tr>
      """
    $('#resend_csam_reports_table').append(dialog_table_row)

  $('#resend_csam_reports_dialog').dialog 'open'


open_forward_report_dialog = (entries) ->
  $('#forward_csam_reports_table tbody').empty()
  $(entries).each ->
    dialog_table_row = """
      <tr>
        <td class='report-entry-id-col'>
          #{this.entry_id}
        </td>
        <td class='entry-url-col'>
          #{this.url}
        </td>
        <td class='source-col'>
          #{this.source}
        </td>
        <td class='report-col'>
          #{missing_report(this.report_id)}
        </td>
      </tr>
      """

    $('#forward_csam_reports_table').append(dialog_table_row)

  $('#forward_csam_reports_dialog').dialog 'open'

missing_report = (report_id) ->
  if report_id == 'No Report'
    return '<span class="missing-data">No Report</span>'
  else
    return report_id
