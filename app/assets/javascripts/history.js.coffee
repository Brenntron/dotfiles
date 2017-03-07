$ ->
  $(document).on 'click', '.toggle_comment_form', ->
    $('#showAddNotesToggle, #hideAddNotesToggle, #addResearchNoteForm').toggle()

  $(document).on 'click', '.sort_history', ->
    $('#notesChronToggle, #notesTLDRToggle').toggle()
    order = $('#list_history')
    order.children().each (index, div) ->
      order.prepend div
    if order.hasClass('reverse')
      order.removeClass('reverse')
    else
      order.addClass('reverse')


  $(document).on 'click', '.show-note-toggle', ->
    $(this).addClass('hidden')
    $(this).siblings('.hide-note-toggle').removeClass('hidden').show()
    $(this).closest('.research-note').children('.col-xs-12').first().hide()

  $(document).on 'click', '.hide-note-toggle', ->
    $(this).addClass('hidden')
    $(this).siblings('.show-note-toggle').removeClass('hidden').show()
    $(this).closest('.research-note').children('.col-xs-12').first().show()



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
        window.location.reload()
      error: (response) ->
        $('.alert_comment').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_comment').hide 'blind', {}, 8000
          return
        ), 8000
    }