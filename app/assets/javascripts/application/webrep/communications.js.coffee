$ ->

  # Generic email show stuff
  $('.email-row').on 'click', ->
    clean_up_current_email_view()
    handle_current_email_row($(this))

    email_id = $(this).attr('email_id')

    std_msg_ajax(
      method: 'PUT'
      url: "/api/v1/escalations/webrep/dispute_emails/#{email_id}"
      data: {status: 'read'}
      success_reload: false
      success: (response) ->
        $('.email-header-information').removeClass('hidden')
        populate_communication_details(response)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email.", reload: false)
    )


  populate_communication_details = (email) ->
    $('.communication-subject')[0].innerHTML = email.subject
    $('.communication-subject')[1].innerHTML = "Re:" + email.subject
    $('.author-username')[0].innerHTML = email.from
    $('.receiver-email')[0].innerHTML = email.to
    $('.receiver-email')[1].innerHTML = email.from
    $('.email-msg-content')[0].innerHTML = email.body

    date = moment.utc(email.created_at)
    $('.email-datetime')[0].innerHTML = moment(date).format('YYYY-MM-DD') + "<br>" + moment(date).format('HH:mm:ss')


  clean_up_current_email_view = ->
    $('.duplicate-current-email-view').remove();
    former_element = $('.current-email-view').removeClass('current-email-view')

  handle_current_email_row = (row) ->
    dup_row = row.clone().addClass('duplicate-current-email-view').insertAfter(row)
    row.addClass('current-email-view')
    row.removeClass('email-unread')
    row.addClass('email-read')


  # Email reply creation and attachments

  $('.reply-button').on 'click', ->
    $('#email-reply').removeClass('hidden')

  $('.attachment-reply').on 'click', ->
    $('#file-fields').before("<span><input class= 'file_attachment' name='attachment' type='file'/></span>")
    $('.file_attachment:last').after("<button class='delete_attachment'>x</button>")
    $('.file_attachment:last').click()

  $('body').on 'click', '.delete_attachment', ->
    $(this).parent().remove()


  $('#reply').on 'click', ->

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    form_data = new FormData()
    $.each $('.file_attachment'), (attachment) ->
      form_data.append("attachments[#{attachment}]", $('.file_attachment')[attachment].files[0])

    form_data.append('body', $('.email-reply-body').val() + "\n" + $('.email-msg-content')[0].textContent)
    form_data.append('dispute_id', $('input[name="dispute_id"]').val())
    form_data.append('to', $('.receiver-email')[1].textContent)
    form_data.append('subject', $('.communication-subject')[1].textContent)
    form_data.append('dispute_email_id', $('.current-email-view').attr('email_id'))


    $.ajax(
      headers: headers
      method: 'POST'
      url: '/api/v1/escalations/webrep/dispute_emails'
      data: form_data
      contentType: false
      processData: false
      success_reload: true
      success: (response) ->
        std_msg_success('Email Sent.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Email was not sent", reload: false)
    )


  # New email handlers

  $('.new-attachment').on 'click', ->
    $('#file-fields-new').before("<span><input class= 'file_attachment_new' name='attachment' type='file'/></span>")
    $('.file_attachment_new:last').after("<button class='delete_attachment_new'>x</button>")
    $('.file_attachment_new:last').click()

  $('body').on 'click', '.delete_attachment_new', ->
    $(this).parent().remove()


  $('#new-email').on 'click', (e) ->

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    form_data = new FormData()
    $.each $('.file_attachment_new'), (attachment) ->
      form_data.append("attachments[#{attachment}]", $('.file_attachment_new')[attachment].files[0])

    form_data.append('body', $('.new-body').val())
    form_data.append('dispute_id', $('input[name="dispute_id"]').val())
    form_data.append('to', $('.new-receiver').val())
    form_data.append('subject', $('.new-subject').val())

    if $('form')[0].checkValidity() == true
      e.preventDefault()
      $.ajax(
        headers: headers
        method: 'POST'
        url: '/api/v1/escalations/webrep/dispute_emails'
        data: form_data
        contentType: false
        processData: false
        success_reload: true
        success: (response) ->
          $('#newEmail').modal('hide');
          std_msg_success('Email Sent.', [], reload: true)
        error: (response) ->
          $('#newEmail').modal('hide');
          std_api_error(response, "Email was not sent", response, reload: false)
      )


    # Notes (Comments) related communications stuff

  $('.note-delete-button').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()

    std_msg_ajax(
      method: 'DELETE'
      url: "/api/v1/escalations/webrep/dispute_comments/#{comment_id}"
      data: {current_user_id: current_user_id}
      success_reload: false
      success: (response) ->
        std_msg_success('Note Deleted.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Note could not be deleted.", reload: false)
    )

  $('.note-edit-button').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()

    std_msg_ajax(
      method: 'PUT'
      url: "/api/v1/escalations/webrep/dispute_comments/#{comment_id}"
      data: {current_user_id: current_user_id}
      success_reload: false
      success: (response) ->
        std_msg_success('Note Updated.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Note could not be updated.", reload: false)
    )

