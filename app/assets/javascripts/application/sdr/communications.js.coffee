$ ->
  # Generic email show stuff
  $('#select-sdr-reply-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.reply-body').val(response.json.body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  # New email handlers
  $('#select-new-sdr-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.new-body').val(response.json.body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('#edit-sdr-template').on 'click', ->
    populate_template_details()

    template_id = $(this).attr('template_id')
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('#edit-template-name')[0].value = response.json.template_name
        $('#edit-template-desc')[0].value = response.json.description
        $('#edit-template-body')[0].value = response.json.body
        $('#template-id')[0].value = response.json.id
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('#edit-sdr-email-template').on 'click', ->
    template_id = $('#template-id')[0].value
    template_name = $('#edit-template-name')[0].value
    description = $('#edit-template-desc')[0].value
    body = $('#edit-template-body')[0].value

    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
      data: {template_name: template_name, description: description, body: body}
      success_reload: true
      success: (response) ->
        std_msg_success('Email Template Updated.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error updating the email template.", reload: false)
    )

  $('#delete-sdr-template').on 'click', ->
    template_id = $(this).attr('template_id')
    confirmation = confirm('Are you sure you want to delete this template?')

    if confirmation
      std_msg_ajax(
        method: 'DELETE'
        url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
        success_reload: true
        success: (response) ->
          std_msg_success('Email Template Deleted.', [], reload: true)
        error: (response) ->
          std_api_error(response, "Email Template could not be deleted.", reload: false)
      )

  $('#save-sdr-email-template').on 'click', (e) ->
    template_name = $('#new-template-name')[0].value
    description = $('#new-template-desc')[0].value
    body = $('#new-template-body')[0].value

    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/sdr/email_templates"
      data: {template_name: template_name, description: description, body: body}
      success_reload: false
      success: (response) ->
        std_msg_success('Email Template Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error creating the email template.", reload: false)
    )

  # Notes (Comments) related communications stuff
  # Delete Note
  $('#sdr-note-delete-button').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()

    std_msg_confirm('Are you sure you want to delete this note?', [])

    $('.confirm').on 'click', ->
      std_msg_ajax(
        method: 'DELETE'
        url: "/escalations/api/v1/escalations/sdr/dispute_comments/#{comment_id}"
        data: {current_user_id: current_user_id}
        success_reload: true
        error: (response) ->
          std_api_error(response, "Note could not be deleted.", reload: false)
      )

  # Editing a Note
  $('#sdr-update-note').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()
    editable_note_block = $(".note-block" + comment_id)
    updated_comment = editable_note_block[0].innerText

    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/sdr/dispute_comments/#{comment_id}"
      data: {current_user_id: current_user_id, comment: updated_comment}
      success_reload: true
      error: (response) ->
        std_api_error(response, "Note could not be updated.", reload: false)
    )

  # New Note
  $('#new-sdr-case-note-save-button').on "click", ->
    comment = $('.new-case-note-textarea')[0].innerText
    dispute_id = $('input[name="dispute_id"]').val()
    user_id = $('input[name="current_user_id"]').val()

    if comment.trim().length > 0
      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/sdr/dispute_comments"
        data: {user_id: user_id, comment: comment, sender_domain_reputation_dispute_id: dispute_id}
        success_reload: true
        error_prefix: 'Note could not created.'
        failure_reload: false
      )
    else
      std_msg_error("Note is blank. Delete note?",'')

  $('#edit-sdr-email-template').on 'click', ->
    template_id = $('#template-id')[0].value
    template_name = $('#edit-template-name')[0].value
    description = $('#edit-template-desc')[0].value
    body = $('#edit-template-body')[0].value

    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/sdr/email_templates/#{template_id}"
      data: {template_name: template_name, description: description, body: body}
      success_reload: true
      success: (response) ->
        std_msg_success('Email Template Updated.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error updating the email template.", reload: false)
    )

  populate_template_details =  ->
    $('#edit-template-form-wrapper').show()
    $('#edit-template-form-wrapper').contents().show()
    $('#create-email-template').hide()
    $('#edit-email-template').removeClass('hidden')
    $('#edit-sdr-email-template').removeClass('hidden')
    $('#cancel-edit-email-template').removeClass('hidden')
    $('#edit-template-form-wrapper').animate {
      height: 256
      borderWidth: '1px'
    }, 300
