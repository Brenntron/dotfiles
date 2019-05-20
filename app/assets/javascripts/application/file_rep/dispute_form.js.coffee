$ ->

  $('#new-file-rep-form').on 'submit', (e) ->
    e.preventDefault()

    $('#loader-modal').modal({
      keyboard: false,
    })

    $('#loader-modal').show()
    $('.modal-backdrop').show()

    shas_input_type = $('#shas_type_text').attr('name')
    shas_full_text = $('#shas_list').val()
    disposition_suggested = $('#disposition_suggested').val()
    assignee = $('#assignee').val()

    # delimiters: split the shas by either newline/comma/tab/semi
    shas_array = shas_full_text.split(/[\s,;]+/)

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/file_rep/disputes/form'
      method: 'POST'
      data:
        shas_array: shas_array,
        disposition_suggested: disposition_suggested,
        assignee: assignee,
        shas_input_type: shas_input_type
      success: (response) ->
        $('#loader-modal').modal 'hide'
        $('.modal-backdrop').hide()
        std_msg_success('File Reputation Ticket created.', [], reload: true)
      error: (response) ->
        $('#loader-modal').modal 'hide'
        $('.modal-backdrop').hide()
        std_msg_error('Unable to create File Reputation Ticket', [response.responseJSON.message], reload: false)
    )
