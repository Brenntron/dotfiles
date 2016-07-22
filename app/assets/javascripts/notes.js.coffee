$ ->
  $(document).on 'click', '#researchNotesEditBtn, #researchNotesCancelBtn', (e) ->
    e.preventDefault()
    $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
    if $('textarea[name="research_notes"]').attr("readonly")
      $('textarea[name="research_notes"]').attr("readonly", false)
    else
      $('textarea[name="research_notes"]').attr("readonly", true)

  $(document).on 'click', '#committerNotesEditBtn, #committerNotesCancelBtn', (e) ->
    e.preventDefault()
    $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
    if $('textarea[name="committer_notes"]').attr("readonly")
      $('textarea[name="committer_notes"]').attr("readonly", false)
    else
      $('textarea[name="committer_notes"]').attr("readonly", true)

  $(document).on 'click', '#researchNotesSaveBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="research_notes"]').val())
    data.append( 'note[note_type]', $('input[name="note_type"]').val())
    if $('input[name="note_id"]').val()
      data.append( 'note[id]', $('input[name="note_id"]').val())
    $.ajax {
      url: "/notes"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').addClass('success').show().html('Notes saved')
        $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
        $('textarea[name="research_notes"]').attr("readonly", true)
        if !$('input[name="note_id"]').val()
          $('#notes_form').append('<input type="hidden" name="note_id" value='+response.note.id+'>')
        $('#researchNotesPublishBtn').attr('disabled', false)
      error: (response) ->
        $('.alert_notes').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 500
          return
        ), 5000
    }

  $(document).on 'click', '#committerNotesSaveBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="committer_notes"]').val())
    data.append( 'note[note_type]', $('input[name="committer_type"]').val())
    if $('input[name="committer_note_id"]').val()
      data.append( 'note[id]', $('input[name="committer_note_id"]').val())
    $.ajax {
      url: "/notes"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').addClass('success').show().html('Notes saved')
        $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
        $('textarea[name="committer_notes"]').attr("readonly", true)
        if !$('input[name="committer_note_id"]').val()
          $('#committer_notes_form').append('<input type="hidden" name="committer_note_id" value='+response.note.id+'>')
        $('#committerNotesPublishBtn').attr('disabled', false)
      error: (response) ->
        $('.alert_notes').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 500
          return
        ), 5000
    }

  $(document).on 'click', '#researchNotesPublishBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="research_notes"]').val())
    data.append( 'note[note_type]', $('input[name="note_type"]').val())
    data.append( 'note[id]', $('input[name="note_id"]').val())
    $.ajax {
      url: "/notes/publish_to_bugzilla"
      data: data
      processData: false
      contentType: false
      type: 'PUT'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('textarea[name="research_notes"]').val(response.notes)
        $('#researchNotesPublishBtn').attr('disabled', true)
        $('#notes_form input[name="note_id"]').remove()
      error: (response) ->
        $('.alert_notes').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 500
          return
        ), 5000
    }

  $(document).on 'click', '#committerNotesPublishBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="committer_notes"]').val())
    data.append( 'note[note_type]', $('input[name="committer_type"]').val())
    data.append( 'note[id]', $('input[name="committer_note_id"]').val())
    $.ajax {
      url: "/notes/publish_to_bugzilla"
      data: data
      processData: false
      contentType: false
      type: 'PUT'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('textarea[name="committer_notes"]').val('')
        $('#committerNotesPublishBtn').attr('disabled', true)
        $('#committer_notes_form input[name="committer_note_id"]').remove()
      error: (response) ->
        $('.alert_notes').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 500
          return
        ), 5000
    }
