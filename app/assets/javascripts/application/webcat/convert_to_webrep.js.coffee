## Convert webcat to webrep
## Enable / disable button to attempt based on if anything is selected
$(document).on 'click', '#complaints-index tr, #complaints_check_box, #complaints_select_all', ->
  if $('tr.selected').length == 1
    $('#convert-ticket-button').removeAttr('disabled')
  else
    $('#convert-ticket-button').attr('disabled', 'disabled')


# Prepare ticket for converting
window.prep_complaint_to_convert = () ->
  if $('tr.selected').length > 1
# This shouldn't happen, but just in case
    std_api_error('Can only convert 1 complaint at a time.')
  else
# get all data associated with the selected row
    complaint_row = $('tr.selected')[0]
    row_data = $('#complaints-index').DataTable().row(complaint_row).data()

    complaint_id = row_data.complaint_id
    summary = row_data.description
    entries_table = $('#entries-to-convert tbody')
    entry_id = row_data.entry_id

    # clear residual info from prev selections
    $('#complaint-id-to-convert').empty()
    $('.convert-entry-count').empty()
    $(entries_table).empty()
    $('#convert-ticket-summary').empty()
    $('#convert-to-webrep').attr('disabled', 'disabled')

    std_msg_ajax(
      method: 'POST'
      url: '/escalations/api/v1/escalations/webcat/complaints/view_complaint'
      data:
        complaint_entry_id: entry_id
      success: (response) ->
        response = $.parseJSON(response)
        entries = response.data.complaint_entries
        entry_count = entries.length

        # now that we have parent data, check complaint status & source
        complaint_status = response.data.complaint.status
        complaint_source = response.data.complaint.ticket_source

        if complaint_source == 'talos-intelligence' || complaint_source == 'talos-intelligence-api'
          if complaint_status == 'NEW' || complaint_status == 'ACTIVE' || complaint_status == 'REOPENED'
# populate the dropdown
            $('#complaint-id-to-convert').text(complaint_id)
            $('.convert-entry-count').text('(' + entry_count + ')')

            # extra handling to deal with too many entries and overlapping issues with selectize
            if entry_count > 8
              $('.convert-entry-table-wrapper').addClass('max-scroll')
            else
              $('.convert-entry-table-wrapper').removeClass('max-scroll')

            $(entries).each ->
              if this.entry_type == 'IP'
                entry_content = this.ip_address
              else
                entry_content = this.uri

              entry_row = '<tr><td>' + this.id + '</td><td class="entry-content-to-convert">' + entry_content + '</td>' +
                '<td class="text-center entry-disposition">' +
                '<div class="inline-radio-wrapper"><label for="' + this.id + '-fp-radio" title="Customer says the website is safe and should be allowed.">FP</label><input type="radio" class="disposition-radio" name="disposition-' + this.id + '" value="fp" id="' + this.id + '-fp-radio"/></div>' +
                '<div class="inline-radio-wrapper"><label for="' + this.id + '-fn-radio" title="Customer says the website is malicious and should be blocked">FN</label><input type="radio" class="disposition-radio" name="disposition-' + this.id + '" value="fn" id="' + this.id + '-fn-radio"/></div>' +
                '</td></tr>'

              $(entries_table).append(entry_row)

            $('#convert-ticket-summary').append(summary)
            $('.entry-disposition > .inline-radio-wrapper > label').tooltipster
              theme: [
                'tooltipster-borderless'
                'tooltipster-borderless-customized'
              ]

          else
            std_msg_error('Ticket cannot be converted', ['Selected entry\'s parent ticket is not in a convertible (open) status.'])
            return

        else
          std_msg_error('Ticket cannot be converted', ['Selected ticket is not a customer ticket from talos-intelligence.'])
          return

      error: (response) ->
        console.log response
        std_msg_error('Error preparing ticket for conversion', [response])
    )


convert_complaint_to_webrep = () ->
# get the parent ticket info
  complaint_id = parseInt($('#complaint-id-to-convert').text())
  summary = $('#convert-ticket-summary').val()
  submission_type = $('input[name=ticket-type]:checked').val()

  # get the entries
  suggested_dispositions = []
  entry_rows = $('#entries-to-convert tbody tr')
  $(entry_rows).each ->
    entry_content = $(this).find('.entry-content-to-convert').text()
    disp_radio_name = $(this).find('input[type=radio]').attr('name')
    entry_disposition = $(this).find('input[name=' + disp_radio_name + ']:checked').val()
    suggested_dispositions.push(entry: entry_content, suggested_disposition: entry_disposition)

  std_msg_ajax(
    method: 'POST'
    url: '/escalations/api/v1/escalations/webcat/complaints/convert_ticket'
    data: {
      complaint_id: complaint_id
      summary: summary
      submission_type: submission_type
      suggested_dispositions: suggested_dispositions
    }
    success: (response) ->
      console.log response
      std_msg_success('Success',["Complaint converted to Reputation Dispute."], reload: true)
    error: (response) ->
      std_msg_error('Error converting ticket', ['Complaint unable to be converted to Reputation Dispute.'], reload: false)
  )


$ ->
  # check prior to enabling submit convert to webrep button
  $('#convert-ticket-dropdown').click ->
    # find all the radios
    radios = $(this).find('input:radio')
    # separate into groups by name & then grab only the unique names
    radio_names = []
    $(radios).each ->
      group = $(this).attr('name')
      radio_names.push(group)
    radio_groups = Array.from(new Set(radio_names))

    # make sure each radio group has something checked
    allchecked = 0
    $(radio_groups).each ->
      val = $('input[name=' + this + ']:checked').val()
      unless (val == undefined) || (val == null)
        allchecked++

    if allchecked == radio_groups.length
      $('#convert-to-webrep').removeAttr('disabled')
    else
      $('#convert-to-webrep').attr('disabled', 'disabled')


  $('#convert-to-webrep').click ->
    convert_complaint_to_webrep()