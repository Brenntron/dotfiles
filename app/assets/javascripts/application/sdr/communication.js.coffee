$(window).load ->
  # New Note

  $('#sdr-new-case-note-button').on "click", ->
    $('.new-case-note-row').show()
    $(this).hide()

  $('#sdr-new-case-note-cancel-button').on "click", ->
    $('.new-case-note-row').hide()
    $('#new-case-note-button').show()
    $('.new-case-note-textarea').empty()

  $('#sdr-new-case-note-save-button').on "click", ->
    comment = $('.new-case-note-textarea')[0].innerText
    dispute_id = $('input[name="dispute_id"]').val()
    user_id = $('input[name="current_user_id"]').val()

    if comment.trim().length > 0
      std_msg_ajax(
        method: 'POST'
        url: "/escalations/api/v1/escalations/sdr/dispute_comments"
        data: {user_id: user_id, comment: comment, dispute_id: dispute_id}
        success_reload: true
        error_prefix: 'Note could not created.'
        failure_reload: false
      )
    else
      std_msg_error("Note is blank. Delete note?",'')
