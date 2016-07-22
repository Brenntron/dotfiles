$ ->
  $(document).on 'click', '.toggle_comment_form', ->
    $('#showAddNotesToggle, #hideAddNotesToggle, #addResearchNoteForm').toggle()

  $(document).on 'submit', '#addResearchNoteForm', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="comment"]').val())
    data.append( 'note[note_type]', $('input[name="comment_type"]').val())
    $.ajax {
      url: "/notes/publish_to_bugzilla"
      data: data
      processData: false
      contentType: false
      type: 'PUT'
      dataType: 'json'
      success: (response) ->
        $('.alert_comment').addClass('success').show().html('Comment saved and published to bugzilla')
        $('textarea[name="comment"]').val('')
        $('#showAddNotesToggle, #hideAddNotesToggle, #addResearchNoteForm').toggle()
      error: (response) ->
        $('.alert_comment').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_comment').hide 'blind', {}, 500
          return
        ), 5000
    }