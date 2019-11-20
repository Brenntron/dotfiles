$ ->
  $('#select-filerep-reply-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/file_rep/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.reply-body').val(response[0].body + "\n \n" + window.reply_body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('#select-new-filerep-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/file_rep/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.new-body').val(response[0].body)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('.edit-filerep-template').on 'click', ->
    populate_template_details()

    template_id = $(this).attr('template_id')
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/file_rep/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('#edit-template-name')[0].value = response[0].template_name
        $('#edit-template-desc')[0].value = response[0].description
        $('#edit-template-body')[0].value = response[0].body
        $('#template-id')[0].value = response[0].id
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )


  $('#edit-filerep-email-template').on 'click', ->
    template_id = $('#template-id')[0].value
    template_name = $('#edit-template-name')[0].value
    description = $('#edit-template-desc')[0].value
    body = $('#edit-template-body')[0].value

    std_msg_ajax(
      method: 'PUT'
      url: "/escalations/api/v1/escalations/file_rep/email_templates/#{template_id}"
      data: {template_name: template_name, description: description, body: body}
      success_reload: true
      success: (response) ->
        std_msg_success('Email Template Updated.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error updating the email template.", reload: false)
    )


  $('.delete-filerep-template').on 'click', ->
    template_id = $(this).attr('template_id')
    confirmation = confirm('Are you sure you want to delete this template?')

    if confirmation
      std_msg_ajax(
        method: 'DELETE'
        url: "/escalations/api/v1/escalations/file_rep/email_templates/#{template_id}"
        success_reload: true
        success: (response) ->
          std_msg_success('Email Template Deleted.', [], reload: true)
        error: (response) ->
          std_api_error(response, "Email Template could not be deleted.", reload: false)
      )

  $('#save-filerep-email-template').on 'click', (e) ->
    template_name = $('#new-template-name')[0].value
    description = $('#new-template-desc')[0].value
    body = $('#new-template-body')[0].value

    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/file_rep/email_templates"
      data: {template_name: template_name, description: description, body: body}
      success_reload: false
      success: (response) ->
        std_msg_success('Email Template Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "There was an error creating the email template.", reload: false)
    )

  populate_template_details =  ->
    $('#edit-template-form-wrapper').show()
    $('#edit-template-form-wrapper').contents().show()
    $('#create-email-template').hide()
    $('#edit-email-template').removeClass('hidden')
    $('#edit-filerep-email-template').removeClass('hidden')
    $('#cancel-edit-email-template').removeClass('hidden')
    $('#edit-template-form-wrapper').animate {
      height: 256
      borderWidth: '1px'
    }, 300