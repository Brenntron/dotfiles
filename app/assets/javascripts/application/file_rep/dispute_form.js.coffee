$ ->
  document.getElementById('file_rep_submit').disabled = true
  $('#sha_errors_list').hide()

  $('#shas_list').on 'input', (e) ->
    $('#sha_errors_list .sha-msg').remove()
    document.getElementById('file_rep_submit').disabled = true
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
      if !document.getElementById('bugzilla-login-notice')
        document.getElementById('file_rep_submit').disabled = false

  $('#new-file-rep-form').on 'submit', (e) ->
    e.preventDefault()
    $('#loader-modal').modal({
      keyboard: false,
    })

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
        uniques = response.json.uniques
        duplicates = response.json.duplicates
        uniques_stat = false
        duplicates_stat = false

        if Object.keys(uniques).length > 0
          success_message = 'Tickets have been created for the following SHA256 hashes:'
          uniques_stat = true

          uniques_string = ''

          for k,v of uniques
            uniques_string += "<a href='/escalations/file_rep/disputes/#{k}'>#{v}</a></br>"

        if duplicates.length > 0
          dup_message = 'The following SHA256 hashes are duplicates (no ticket created):'
          duplicates_stat = true

          duplicates_string = duplicates.join '<br/>'

        if uniques_stat && duplicates_stat
          std_msg_error('Unable to create all File Reputation Tickets', [success_message, '<span class="code-content">' + uniques_string + '</span>', dup_message, '<span class="code-content">' + duplicates_string + '</span>'], reload: true)
        else if uniques_stat && !duplicates_stat
          std_msg_success('File Reputation Tickets Created', [success_message, '<span class="code-content">' + uniques_string + '</span>'], reload: true)
        else
          std_msg_error('Unable to create File Reputation Tickets', [dup_message, '<span class="code-content">' + duplicates_string + '</span>'], reload: true)

      error: (response) ->
        message = response.responseJSON.message
        $('#loader-modal').modal 'hide'
        std_msg_error('Unable to create File Reputation Ticket', [message], reload: false)
    )

  validateSha = (sha) ->
    sha_regex = new RegExp('[A-Fa-f0-9]{64}')
    return sha_regex.test sha
