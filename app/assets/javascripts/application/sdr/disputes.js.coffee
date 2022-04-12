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
  dispute_id = $('#dispute_id').text()

  if statusName == 'RESOLVED_CLOSED'
    resolution = $("#show-edit-ticket-status-dropdown").find('input[name=dispute-resolution]:checked').val()
  else
    std_msg_error('No resolution selected', ['Please select a ticket resolution.'])

  data = {
    dispute_ids: [ dispute_id ]
    status: statusName
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

window.sdr_toolbar_unassign_dispute = () ->
  single_id = $('#dispute_id').text()
  entry_ids = [single_id]

  data = {
    'dispute_ids': entry_ids
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/unassign_all'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      window.location.reload()
    error: (response) ->
      popup_response_error(response, 'Error removing assignee')
  )

window.take_single_sdr_dispute = (id) ->
  dispute_ids = [ id ]

  std_msg_ajax(
    method: 'PATCH'
    url: "/escalations/api/v1/escalations/sdr/disputes/take_disputes"
    data: { dispute_ids: dispute_ids }
    error_prefix: 'Error updating ticket.'
    success_reload: true
    success: (response) ->
      if response.dispute_ids.length > 0
        show_message('success', 'Ticket assignment has been updated!', 5)
        location.reload()
      else
        show_message('error', 'Ticket assnigment could not be updated.', 5)
        location.reload()
  )

window.sdr_toolbar_show_change_assignee = () ->
  singleId = $('#dispute_id').text()
  disputeIdArray = [singleId]
  new_assignee = $('#index_target_assignee option:selected').val()
  data = {
    'dispute_ids': disputeIdArray,
    'new_assignee': new_assignee
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/change_assignee'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->
      show_message('success', 'Ticket assignment has been updated!', 5)
      window.location.reload()
    error: (response) ->
      show_message('error', 'Ticket assignment could not be updated.', 5)
      std_msg_error('No Tickets Selected', ['Select at least one ticket to assign to yourself.'])
  )

$ ->
  $('.sdr-ticket-status-radio').click ->
    if $(this).is(':checked')
      wrapper = $(this).parent()
      $(wrapper).addClass('selected')

    if $(this).attr('id') == 'RESOLVED_CLOSED'
      $('#show-ticket-resolution-submenu').show()
      stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
      $('#ticket-non-res-submit').hide()
      $(stat_comment).val('')
    else
      $('#ticket-non-res-submit').show()
      res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
      $('.ticket-resolution-radio').prop('checked', false)
      $('#show-ticket-resolution-submenu').hide()
      $(res_comment[0]).val('')
