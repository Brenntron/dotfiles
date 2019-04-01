window.pop_up_create_research_modal = (this_tag) ->
  $("#create_research_bugs_modal").modal('show')

window.create_research_bug = (this_tag) ->
  $("#create_research_submit").hide()
  $("#create_research_submit_wait").removeClass('hidden').show()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

  new_summary_line = ""
  new_research_notes = ""
  bid = $('.bugzilla_id').text()

  new_summary_line = $('#new_summary_line').val()
  new_research_notes = $('#new_research_notes').val()
  new_research_description = $("#new_research_description").val()

  $.ajax(
    url: '/api/v1/bugs/duplicate_bug'
    method: 'POST'
    headers: headers
    data: { id: bid, summary: new_summary_line, research_notes: new_research_notes, description: new_research_description}
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
        $("#create_research_submit_wait").addClass('hidden').hide()
        $("#create_research_submit").show()
      else
        url = json.callback_url

        window.open(url, '_blank');
        window.location.reload()


    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      $("#create_research_submit_wait").addClass('hidden').hide()
      $("#create_research_submit").show()
  , this)

window.pop_up_reopen_modal = (this_tag) ->
  $("#reopen_research_bugs_modal").modal('show')

window.reopen_research_bug = (this_tag) ->
  $("#reopen_reserch_submit").hide()
  $("#reopen_reserch_submit_wait").removeClass('hidden').show()
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  comment = ""
  bid = $('.bugzilla_id').text()
  comment = $('#reopen_bug_message').val()

  checked_boxes = $(".reopen_bug_checkbox:checked")
  checked_ids = []
  for checked_box in checked_boxes
    checked_ids.push checked_box.name

  $.ajax(
    url: '/api/v1/bugs/reopen_bugs'
    method: 'POST'
    headers: headers
    data: { comment: comment, ids: checked_ids, id: bid}
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      else
        urls = json.urls_to_open
        for url in urls
          window.open(url, '_blank');
        window.location.reload()


    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      $("#reopen_reserch_submit_wait").addClass('hidden').hide()
      $("#reopen_reserch_submit").show()
  , this)

window.escalation_acknowledge = (this_tag,bug_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  comment = ""
  switch $('input[name=acknowledge_response]:checked').val()
    when 'ack1'
      comment = $('input[name=acknowledge_response]:checked').parent().text()
    when 'ack2'
      comment = $('textarea#acknowledge_response_custom').val()
  $.ajax(
    url: '/api/v1/bugs/' + bug_id + '/acknowledge'
    method: 'PATCH'
    headers: headers
    data: { comment: comment}
    success: (response) ->
      $('#acknowledge_esc_form_button').hide()
  , this)

window.take_escalation_acknowledge = (this_tag,bug_id) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  comment = ""
  switch $('input[name=acknowledge_response_take]:checked').val()
    when 'ack1'
      comment = $('input[name=acknowledge_response_take]:checked').parent().text()
    when 'ack2'
      comment = $('textarea#acknowledge_response_custom_take').val()
  $("#take-bug-"+bug_id).hide()
  $("#bug-wait-"+bug_id).show()
  $('#loading_image').removeClass('hidden').show()
  $.ajax {
    url: '/api/v1/bugs/'+bug_id+'/subscribe-acknowledge'
    data: {
      committer: false,
      comment: comment
    }
    method: 'post'
    headers: headers
    success: (response) ->
      location.reload()
    error: (response) ->
      alert ("Sorry, you can not take this bug\n" + response.responseJSON.error)
      location.reload()
  }

window.populate_bugid_in_modal = (bug_id) ->
  $('#acknowledge_bug_id').val(bug_id)
  $('#take_acknowledge_esc').modal('show')

