$ ->

  $('#notes-table').dataTable(
    'dom': '<<"toolbar" lf><t>ip>'
    language: {
      searchPlaceholder: 'Search notes'
    }
    processing: true
    serverSide: true
    pageLength: 25
    ajax: $('#notes-table').data('source')
    pagingType: 'full_numbers'
    responsive: true
    columns: [
      {data: 'id'}
      {data: 'bug_id'}
      {
        data: 'note_type'
        render: (data) ->
          '<span class="emphasis">' + data + '</span>'
      }
      {
        data: 'comment'
        orderable: false
        render: (data) ->
          '<span class="code-snippet">' + data + '</span>'
      }
      {data: 'author', class: 'col-nowrap'}
      {data: 'notes_bugzilla_id', class: 'col-nowrap'}
      {data: 'created_at', class: 'col-nowrap'}
      {data: 'updated_at', class: 'col-nowrap'}
      {
        data: 'links', class: 'td-tools'
        orderable: false
      }
    ])
  # pagingType is optional, if you want full pagination controls.
  # Check dataTables documentation to learn more about
  # available options.

  $(document).on 'click', '#researchNotesSaveBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="research_notes"]').val())
    data.append( 'note[note_type]', $('input[name="note_type"]').val())
    data.append(  'is_research_notes', 'true' )
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
        $('.alert_notes_research').removeClass('error')
        $('.alert_notes_research').addClass('success').show().html('Notes saved')
        $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
        $('textarea[name="research_notes"]').attr("readonly", true)
        $('#researchNotesEditBtn').html('edit')
        $('input[name="research_note_id"]').val(response.id)
        $('#researchNotesPublishBtn').attr('disabled', false)
        window.location.reload()
      error: (response) ->
        $('.alert_notes_reserach').removeClass('success')
        if(response.status == '403')
          $('.alert_notes_research').addClass('error').show().html("<h4>NOTE NOT SAVED: Your session has timed out. Please refresh your browser</h4>")
        else
          $('.alert_notes_research').addClass('error').show().html("<h4>NOTE NOT SAVED: #{response.responseText} - #{response.status} - #{response.statusText}</h4>")
        return
      complete: ->
        setTimeout (->
          $('.alert_notes_research').hide 'blind', {}, 500
          return
        ), 70000
    }

  $(document).on 'click', '#scratchpadNotesSaveBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="scratchpad_notes"]').val())
    data.append( 'note[note_type]', $('input[name="scratchpad_type"]').val())
    if $('input[name="scratchpad_note_id"]').val() != ""
      data.append( 'note[id]', $('input[name="scratchpad_note_id"]').val())
    $.ajax {
      url: "/notes"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType: 'json'
      success: (response) ->
        $('.alert_notes_scratch').removeClass('error')
        $('.alert_notes_scratch').addClass('success').show().html('Notes saved')
        $('#scratchpadNotesCancelBtn, #scratchpadNotesSaveBtn, #scratchpadNotesPublishBtn, #scratchpadNotesEditBtn').toggle()
        $('textarea[name="scratchpad_notes"]').attr("readonly", true)
        $('#scratchpadNotesEditBtn').html('edit')
        $('input[name="scratchpad_note_id"]').val(response.id)
        window.location.reload()
      error: (response) ->
        $('.alert_notes_scratch').removeClass('success')
        $('.alert_notes_scratch').addClass('error').show().html("<h4>#{response.responseText}</h4>")
      complete: ->
        setTimeout (->
          $('.alert_notes_scratch').hide 'blind', {}, 500
          return
        ), 70000
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
        $('.alert_notes_commit').removeClass('error')
        $('.alert_notes_commit').addClass('success').show().html('Notes saved')
        $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
        $('#committerNotesEditBtn').html('edit')
        $('textarea[name="committer_notes"]').attr("readonly", true)
        $('input[name="committer_note_id"]').val(response.id)
        $('#committerNotesPublishBtn').attr('disabled', false)
        window.location.reload()
      error: (response) ->
        $('.alert_notes_commit').removeClass('success')
        $('.alert_notes_commit').addClass('error').show().html("<h4>#{response.responseText}</h4>")
      complete: ->
        setTimeout (->
          $('.alert_notes_commit').hide 'blind', {}, 500
          return
        ), 70000
    }

  $(document).on 'click', '#researchNotesPublishBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="research_notes"]').val())
    data.append( 'note[note_type]', $('input[name="note_type"]').val())
    data.append( 'note[id]', $('input[name="note_id"]').val())
    $('#publishing_note').removeClass('hidden').show()
    $('#researchNotesPublishBtn').addClass('hidden').hide()
    $.ajax {
      url: "/notes/publish_to_bugzilla"
      data: data
      processData: false
      contentType: false
      type: 'PUT'
      dataType: 'json'
      success: (response) ->
        bug = response.bug
        note = response.note
        $('input[name="note_id"]').val(note.id)
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('#researchNotesPublishBtn').attr('disabled', true)
        $('#publishing_note').addClass('hidden').hide()
        $('#researchNotesPublishBtn').removeClass('hidden').show()
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
        $('#publishing_note').addClass('hidden').hide()
        $('#researchNotesPublishBtn').removeClass('hidden').show()
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 5000
          return
        ), 8000
        window.location.reload()
    }

  $(document).on 'click', '#committerNotesPublishBtn', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'note[bugzilla_id]', $('input[name="bugzilla_id"]').val())
    data.append( 'note[comment]', $('textarea[name="committer_notes"]').val())
    data.append( 'note[note_type]', $('input[name="committer_type"]').val())
    data.append( 'note[id]', $('input[name="committer_note_id"]').val())
    $('#publishing_committer_note').removeClass('hidden').show()
    $('#committerNotesPublishBtn').addClass('hidden').hide()
    $.ajax {
      url: "/notes/publish_to_bugzilla"
      data: data
      processData: false
      contentType: false
      type: 'PUT'
      dataType: 'json'
      success: (response) ->
        note = response.note
        $('input[name="committer_note_id"]').val(note.id)
        $('.alert_notes').removeClass('error')
        $('.alert_notes').addClass('success').show().html('Notes published to bugzilla')
        $('#committerNotesPublishBtn').attr('disabled', true)
        $('#publishing_committer_note').addClass('hidden').hide()
        $('#committerNotesPublishBtn').removeClass('hidden').show()
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
        window.location.reload()
      error: (response) ->
        $('.alert_notes').removeClass('success')
        $('.alert_notes').addClass('error').show().html(response.responseText)
        $('#publishing_committer_note').addClass('hidden').hide()
        $('#committerNotesPublishBtn').removeClass('hidden').show()
      complete: ->
        setTimeout (->
          $('.alert_notes').hide 'blind', {}, 5000
          return
        ), 8000
    }

  $(document).on 'click', '#scratchpadNotesEditBtn', (e) ->
    e.preventDefault()
    $('#scratchpadNotesEditArea').focus()

  $(document).on 'click', '#scratchpadNotesCancelBtn', (e) ->
    e.preventDefault()
    $('#scratchpadNotesCancelBtn, #scratchpadNotesSaveBtn, #scratchpadNotesPublishBtn, #scratchpadNotesEditBtn').toggle()
    $('textarea[name="scratchpad_notes"]').attr("readonly", true)

  $(document).on 'click', '#researchNotesEditBtn', (e) ->
    e.preventDefault()
    $('#researchNotesEditArea').focus()

  $(document).on 'click', '#researchNotesCancelBtn', (e) ->
    e.preventDefault()
    $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
    $('textarea[name="research_notes"]').attr("readonly", true)

  $(document).on 'click', '#committerNotesEditBtn', (e) ->
    e.preventDefault()
    $('#committerNotesEditArea').focus()

  $(document).on 'click', '#committerNotesCancelBtn', (e) ->
    e.preventDefault()
    $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
    $('textarea[name="committer_notes"]').attr("readonly", true)

  $(document).on 'focusin',  '#researchNotesEditArea', (e) ->
    if $('textarea[name="research_notes"]').attr("readonly")
      $('#researchNotesCancelBtn, #researchNotesSaveBtn, #researchNotesPublishBtn, #researchNotesEditBtn').toggle()
      $('textarea[name="research_notes"]').attr("readonly", false)

  $(document).on 'focusin',  '#committerNotesEditArea', (e) ->
    if $('textarea[name="committer_notes"]').attr("readonly")
      $('#committerNotesCancelBtn, #committerNotesSaveBtn, #committerNotesPublishBtn, #committerNotesEditBtn').toggle()
      $('textarea[name="committer_notes"]').attr("readonly", false)

  $(document).on 'focusin',  '#scratchpadNotesEditArea', (e) ->
    if $('textarea[name="scratchpad_notes"]').attr("readonly")
      $('#scratchpadNotesCancelBtn, #scratchpadNotesSaveBtn, #scratchpadNotesPublishBtn, #scratchpadNotesEditBtn').toggle()
      $('textarea[name="scratchpad_notes"]').attr("readonly", false)


  $(document).on 'ready page:load', (e) ->
    $('.autosize').each ->
      autosize(this)


  $(document).on('focus.autoExpand', 'textarea.autoExpand', ->
    savedValue = @value
    @value = ''
    @baseScrollHeight = @scrollHeight
    @value = savedValue
    return
  ).on 'input.autoExpand', 'textarea.autoExpand', ->
    minRows = @getAttribute('data-min-rows') | 0
    rows = undefined
    @rows = minRows
    diffHeight = @scrollHeight - @baseScrollHeight
    rows = Math.ceil(diffHeight / 17)
    @rows = minRows + rows
    return

