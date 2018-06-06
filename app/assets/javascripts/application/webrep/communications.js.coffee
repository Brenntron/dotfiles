$ ->
  $('.email-row').on 'click', ->
    clean_up_current_email_view()
    handle_current_email_row($(this))

    email_id = $(this).attr('email_id')
    headers = {'Token': $('input[name="token"]').val()}
    $.ajax {
      headers: headers
      url: "/api/v1/escalations/webrep/dispute_emails/#{email_id}"
      type: 'PUT'
      dataType: 'json'
      data:
        status: 'read'
      success: (response) ->
        $('.email-header-information').removeClass('hidden')
        $('#email-reply').removeClass('hidden')
        populate_communication_details(response)

      error: (response) ->
       alert("There was a problem retrieving email.")
  }


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
    headers = {'Token': $('input[name="token"]').val()}
    email_data = {body: email_body, dispute_id: dispute_id, to: to, subject: subject}
    $.ajax {
      headers: headers
      url: "/api/v1/escalations/webrep/dispute_emails"
      type: 'POST'
      dataType: 'json'
      data: email_data
      success: (response) ->
        alert('Email successfully sent')
      error: (response) ->
        alert("There was a problem sending email.")
    }

