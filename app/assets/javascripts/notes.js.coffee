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
    if $('#researchNotesEditBtn').html()=='edit' && $('input[name="note_id"]').val()
      data.append( 'note[id]', $('input[name="note_id"]').val())
    $.ajax {
      url: "/notes"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes saved')
        $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
        $('textarea[name="research_notes"]').attr("readonly", true)
        $('#researchNotesEditBtn').html('edit')
        $('input[name="research_note_id"]').val(response.note.id)
        $('#researchNotesPublishBtn').attr('disabled', false)
      error: (response) ->
        $('.alert_notes').removeClass('success')
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
    if $('#committerNotesEditBtn').html()=='edit'  && $('input[name="committer_note_id"]').val()
      data.append( 'note[id]', $('input[name="committer_note_id"]').val())
    $.ajax {
      url: "/notes"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes saved')
        $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
        $('#committerNotesEditBtn').html('edit')
        $('textarea[name="committer_notes"]').attr("readonly", true)
        $('input[name="committer_note_id"]').val(response.note.id)
        $('#committerNotesPublishBtn').attr('disabled', false)
      error: (response) ->
        $('.alert_notes').removeClass('success')
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
        bug = response.bug.bug
        note = response.note.note
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('#researchNotesPublishBtn').attr('disabled', true)
        div = '<div class="row top-space research-note">'+
          '<div class="col-xs-6">'+
          '<p class="small text-muted">written by <strong>'+note["author"]+'</strong></p>'+
          '</div>'+
          '<div class="col-xs-6 right">'+
          '<a>'+
          '<span class="show-note-toggle text-muted">[-]</span>'+
          '<span class="hide-note-toggle hidden text-muted">[+]</span>'+
          '</a>'+
          '</div>'+
          '<div class="col-xs-12">'+
          '<pre class="comment">'+note["comment"]+'</pre>'+
          '</div>'+
          '<div class="col-xs-12">'+
          '<p class="line"></p>'+
          '</div>'+
          '</div>'
        if $('#list_history').hasClass('reverse')
          $('#list_history').append(div)
        else
          $('#list_history').prepend(div)
      error: (response) ->
        $('.alert_notes').removeClass('success')
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
        note = response.note.note
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('#committerNotesPublishBtn').attr('disabled', true)
        div = '<div class="row top-space research-note">'+
          '<div class="col-xs-6">'+
          '<p class="small text-muted">written by <strong>'+note["author"]+'</strong></p>'+
          '</div>'+
          '<div class="col-xs-6 right">'+
          '<a>'+
          '<span class="show-note-toggle text-muted">[-]</span>'+
          '<span class="hide-note-toggle hidden text-muted">[+]</span>'+
          '</a>'+
          '</div>'+
          '<div class="col-xs-12">'+
          '<pre class="comment">'+note["comment"]+'</pre>'+
          '</div>'+
          '<div class="col-xs-12">'+
          '<p class="line"></p>'+
          '</div>'+
          '</div>'
        if $('#list_history').hasClass('reverse')
          $('#list_history').append(div)
        else
          $('#list_history').prepend(div)
      error: (response) ->
        $('.alert_notes').removeClass('success')
        $('.alert_notes').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 500
          return
        ), 5000
    }
