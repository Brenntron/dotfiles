$ ->
  $('.email-row').on 'click', ->
    # pull email from href
    email_id = $(this).attr('email_id')
    headers = {'Token': $('input[name="token"]').val()}
    $.ajax {
      headers: headers
      url: "/api/v1/escalations/webrep/dispute_emails/#{email_id}"
      type: 'GET'
      dataType: 'json'
      success: (response) ->
        $('.email-header-information').removeClass('hidden')
        populate_communication_details(response[0])

      error: (response) ->
       alert("There was a problem retrieving email.")
  }


  populate_communication_details = (email) ->
    $('.communication-subject')[0].innerHTML = email.subject
    $('.author-username')[0].innerHTML = email.from
    $('.receiver-email')[0].innerHTML = email.to
    $('.email-msg-content')[0].innerHTML = email.body

    date = moment.utc(email.created_at)
    $('.email-datetime')[0].innerHTML = moment(date).format('YYYY-MM-DD') + "<br>" + moment(date).format('HH:mm:ss')
