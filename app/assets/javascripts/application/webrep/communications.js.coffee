$ ->
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
        $('#email-reply').removeClass('hidden')
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



  $('#reply').on 'click', ->
    email_body = $('.email-reply-body').val() + "\n" + $('.email-msg-content')[0].textContent
    dispute_id = $('input[name="dispute_id"]').val()
    to = $('.receiver-email')[1].textContent
    subject = $('.communication-subject')[1].textContent
    dispute_email_id = $('.current-email-view').attr('email_id')
    email_data = {
      body: email_body,
      dispute_id: dispute_id,
      to: to,
      subject: subject,
      dispute_email_id: dispute_email_id
    }

    std_msg_ajax(
      method: 'POST'
      url: '/api/v1/escalations/webrep/dispute_emails'
      data: email_data
      success_reload: true
      success: (response) ->
        std_msg_success('Email Sent.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Email was not sent", reload: false)
    )

