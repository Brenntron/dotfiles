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
    $('#submit_comment')[0].disabled = true
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
          $('.alert_comment').hide 'blind', {}, 8000
          window.location.reload()
          return
        ), 8000
    }

  $('.synch_history').on 'click', ->
    id = $('input[name="bugzilla_id"]').val()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $(this).attr('disabled', 'disabled')
    $("#synch_history").addClass 'hidden'
    $("#syncing_history").removeClass 'hidden'
    $("#syncing_history").show()
    
    $.ajax(
      url: '/api/v1/bugs/synch_bug/history/' + id
      method: 'GET'
      headers: headers
      success: (response) ->
        $('.alert_comment').addClass('success').show().html('History Sunk.')
        $('#synch_history, #synch_history_synching').toggle()
        window.location.reload()
      error: (response) ->
        $('.alert_comment').addClass('error').show().html('There was a problem sinking the history.')
        $(this).attr('disabled', false)
    , this)