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
        populate_communication_details(response.email, response.attachments)
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email.", reload: false)
    )


  populate_communication_details = (email, attachments) ->
    $('.communication-subject')[0].innerHTML = email.subject
    $('input[type=text].communication-subject').val("Re: " + email.subject)
    $('.author-username')[0].innerHTML = email.from
    $('.receiver-email')[0].innerHTML = email.to
    $('.receiver-email')[1].innerHTML = email.from
    $('.email-msg-content')[0].innerHTML = email.body

    date = moment.utc(email.created_at)
    $('.email-datetime')[0].innerHTML = moment(date).format('YYYY-MM-DD') + "<br>" + moment(date).format('HH:mm:ss')

    for attachment in attachments
      $('#incoming-attachment').removeClass('hidden')
      attachment_div = $('.email-attachments')
      attachment_link = ("<a class=email-attachment-name, href=#{attachment.direct_upload_url}>#{attachment.file_name} </a>")
      attachment_div.append(attachment_link)


  clean_up_current_email_view = ->
    $('.duplicate-current-email-view').remove()
    $('.email-attachments').empty()
    $('#incoming-attachment').addClass('hidden')
    former_element = $('.current-email-view').removeClass('current-email-view')

  handle_current_email_row = (row) ->
    dup_row = row.clone().addClass('duplicate-current-email-view').insertAfter(row)
    row.addClass('current-email-view')
    row.removeClass('email-unread')
    row.addClass('email-read')


  # Email reply creation and attachments

  $('.reply-button').on 'click', ->
    email_reply = $('#email-reply')
    $('#email-reply').removeClass('hidden')
    $('.email-reply-body').focus()

  $('#select-reply-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/api/v1/escalations/webrep/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.reply-body')[0].innerHTML = response[0].body
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('.attachment-reply').on 'click', ->
    $('.file-wrapper-reply').show()
    $('#file-fields').append("<span class='file-attachment-wrapper'><input class= 'file_attachment' name='attachment' type='file'/></span>")
    $('.file_attachment:last').after("<button class='delete_attachment'>x</button>")
    $('.file_attachment:last').click()

  $('body').on 'click', '.delete_attachment', ->
    $(this).parent().remove()


  $('#send-reply').on 'click', ->

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    form_data = new FormData()
    $.each $('.file_attachment'), (attachment) ->
      form_data.append("attachments[#{attachment}]", $('.file_attachment')[attachment].files[0])

    form_data.append('body', $('.email-reply-body').val() + "\n" + $('.email-msg-content')[0].textContent)
    form_data.append('dispute_id', $('input[name="dispute_id"]').val())
    form_data.append('to', $('.receiver-email')[1].textContent)
    form_data.append('subject', $('input[type=text].new-subject').val())
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

  $('#select-new-template').on 'change', ->
    template_id = this.value

    std_msg_ajax(
      method: 'GET'
      url: "/api/v1/escalations/webrep/email_templates/#{template_id}"
      success_reload: false
      success: (response) ->
        $('.new-body')[0].innerHTML = response[0].body
      error: (response) ->
        std_api_error(response, "There was a problem retrieving email template.", reload: false)
    )

  $('.new-attachment').on 'click', ->
    $('#file-fields-new').before("<span class='file-attachment-wrapper'><input class= 'file_attachment_new' name='attachment' type='file'/></span>")
    $('.file_attachment_new:last').after("<button class='delete_attachment_new'>x</button>")
    $('.file_attachment_new:last').click()
    false

  $('body').on 'click', '.delete_attachment_new', ->
    $(this).parent().remove()



  $('#send-new-email').on 'click', (e) ->

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
    # Delete Note

  $('.note-delete-button').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()
    confirmation = confirm('Are you sure you want to delete this note?')

    if confirmation
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

  # Editing a Note

  $('.note-save-button').on "click", ->
    comment_id = $(this).attr('comment_id')
    current_user_id = $('input[name="current_user_id"]').val()
    editable_note_block = $(".note-block" + comment_id)
    updated_comment = editable_note_block[0].innerText

    std_msg_ajax(
      method: 'PUT'
      url: "/api/v1/escalations/webrep/dispute_comments/#{comment_id}"
      data: {current_user_id: current_user_id, comment: updated_comment}
      success_reload: true
      success: (response) ->
        std_msg_success('Note Updated.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Note could not be updated.", reload: false)
    )

  # related to showing and hiding of elements when editing a note
  # Also reverts note to initial state if editing has happened and then been canceled.
  $('.note-block').focus ->
    note_block = this
    initial_content = $(this)[0].innerText
    comment_id = $(this).attr('comment_id')
    save_button = $(".note-save-button" + comment_id)
    cancel_button = $(".note-cancel-button" + comment_id)
    $(cancel_button).on "click", ->
      $(note_block)[0].innerText = initial_content
      save_button.addClass('hidden')
      cancel_button.addClass('hidden')

  $('.note-block').on "keyup", ->
    comment_id = $(this).attr('comment_id')
    save_button = $(".note-save-button" + comment_id)
    save_button.removeClass('hidden')
    cancel_button = $(".note-cancel-button" + comment_id)
    cancel_button.removeClass('hidden')


  # New Note

  $('#new-case-note-button').on "click", ->
    $('.new-case-note-row').show()
    $(this).hide()

  $('.new-case-note-cancel-button').on "click", ->
    $('.new-case-note-row').hide()
    $('#new-case-note-button').show()
    $('.new-case-note-textarea').empty()

  $('.new-case-note-save-button').on "click", ->
    comment = $('.new-case-note-textarea').text()
    dispute_id = $('input[name="dispute_id"]').val()
    user_id = $('input[name="current_user_id"]').val()

    std_msg_ajax(
      method: 'POST'
      url: "/api/v1/escalations/webrep/dispute_comments"
      data: {user_id: user_id, comment: comment, dispute_id: dispute_id}
      success_reload: true
      success: (response) ->
        std_msg_success('Note Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Note could not created.", reload: false)
    )



  $('#newEmailDialog').dialog
    autoOpen: false
    minWidth: 400
    position: { my: "right bottom", at: "right bottom", of: window }
  $('.new-email-button').on 'click', ->
    $('#newEmailDialog').dialog 'open'


    return
  return
