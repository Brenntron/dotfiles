$ ->
  $("#file_rep_submit").attr("disabled", true)
  $('#sha_errors_list').hide()

  $('#shas_list').on 'change', (e) ->
    $('#sha_errors_list .sha-msg').remove()
    $("#file_rep_submit").attr("disabled", true)
    $('#sha_errors_list').hide()
    shas_input_type = $('#shas_type_text').attr('name')
    shas_full_text = $('#shas_list').val()
    disposition_suggested = $('#disposition_suggested').val()
    assignee = $('#assignee').val()

# delimiters: split the shas by either newline/comma/tab/semi
    shas_array = shas_full_text.split(/[\s,;]+/)
    shas_array = shas_array.filter((sha) ->
      sha != ""
    )

    sha_validation_errors = []

    i = 0
    while i < shas_array.length
      if validateSha(shas_array[i])
        i++
      else
        sha_validation_errors.push(shas_array[i])
        i++

    if sha_validation_errors.length > 0
#      $('#sha_errors_list').append("<p>The following are not valid SHAs:</p>")
      $('#sha_errors_list').show()
      i = 0
      while i < sha_validation_errors.length
        $('#sha_errors_list').append("<p class='sha-msg'>"+sha_validation_errors[i]+"</p>")
        i++

    else
      $("#file_rep_submit").attr("disabled", false)




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
    shas_array = shas_array.filter((sha) ->
      sha != ""
    )

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
        parsed_message = response.responseJSON.message.split('@newline')

        std_msg_error('Unable to create File Reputation Ticket', parsed_message, reload: false)
    )

  validateSha = (sha) ->
    sha_regex = new RegExp('[A-Fa-f0-9]{64}')
    return sha_regex.test sha
