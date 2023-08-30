window.auto_resolve_tickets = (current_user, id) ->
  if id != undefined
    #show page single ticket auto resolve
    data = { user_id: current_user, dispute_id: id }
    autoresolve(data).then( (result) ->
      if result.status = 'success'
        std_msg_success('All Dispute Entries Auto Resolved', [], reload: true)
      else
        std_msg_error('Unable to Auto Resolve Dispute Entries', [], reload: false)
    )
  else
    #index page bulk select auto resolve
    checkboxes = $('#disputes-index').find('.dispute_check_box')
    checked_disputes = []
    dispute_promises = []
    $(checkboxes).each ->
      if $(this).is(':checked')
        dispute_id = $(this).val()
        checked_disputes.push(dispute_id)
    if checked_disputes.length == 0
      std_msg_error('No rows selected', ['Please select at least one row.'])
    else
      for dispute_id in checked_disputes
        data = { user_id: current_user, dispute_id: dispute_id }
        dispute_promises.push(data)
      # make all auto resolve calls, messaging function only gets called after all promises resolve
      Promise.allSettled( dispute_promises.map( (data) -> return autoresolve(data)) ).then( (result)-> auto_resolve_msg(result) )

window.autoresolve = (data) ->
  std_msg_ajax(
    url: '/escalations/api/v1/escalations/webrep/disputes/manual_autoresolve'
    method: 'POST'
    data: data
    success: (response) -> return response
    error: (response) -> return response
  )

window.auto_resolve_msg = (result) ->
  #index page auto resolve success/error messaging
  success_message = 'The following tickets have been Auto Resolved:'
  error_message   = 'Error Auto Resolving the following tickets:'
  success_arr   = []
  error_arr     = []
  error  =  false
  success = false

  fulfilled = result.map((r) -> if r.status =='fulfilled' then return r)
  for entry in fulfilled
    {dispute_id, status} = entry.value
    dispute = "<a href='/escalations/webrep/disputes/#{dispute_id}'>#{dispute_id}</a></br>"

    if status == 'success'
      success_arr.push(dispute)
      success = true
    else
      error_arr.push(dispute)
      error = true


  if success
    success_message += "<br><span class='code-content'>#{success_arr.join(' ')}</span>"
    $('#disputes-index').DataTable().draw()

  if error
    error_message += "<br><span class='code-content'>#{error_arr.join(' ')}</span>"

  if success && error
    std_msg_success('Some Tickets Auto Resolved', [success_message, error_message], reload: false)
  else if success
    std_msg_success('Tickets Auto Resolved', [success_message, ""], reload: false)
  else
    std_msg_error('Unable to Auto Resolve Tickets', [error_message,""], reload: false)