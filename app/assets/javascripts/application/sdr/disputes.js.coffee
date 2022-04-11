window.sdr_dispute_status_drop_down = (dispute_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: "/escalations/api/v1/escalations/sdr/disputes/dispute_status/#{dispute_id}"
    method: 'GET'
    headers: headers
    data: {}
    dataType: 'json'
    success: (response) ->
      response = JSON.parse(response)
      status = response.status
      comment = response.comment

      $("#{status}").prop("checked", true)
      if comment?
        $('.ticket-status-comment').text(comment)
  )

window.sdr_show_page_edit_status = (dispute_id) ->
  statusName = $('input[name=dispute-status]:checked').val()
  comment = $('.ticket-status-comment').val()
  dispute_id = $('#dispute_id').text()

  if statusName == 'RESOLVED_CLOSED'
    resolution = $("#show-edit-ticket-status-dropdown").find('input[name=dispute-resolution]:checked').val()
  else
    std_msg_error('No resolution selected', ['Please select a ticket resolution.'])

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
    comment: comment
  }

  if resolution
    data.resolution = resolution
    data.comment = $('.ticket-resolution-comment').val()

  std_msg_ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/set_disputes_status'
    method: 'POST'
    data: data
    error_prefix: 'Unable to update dispute.'
    success_reload: true
  )
