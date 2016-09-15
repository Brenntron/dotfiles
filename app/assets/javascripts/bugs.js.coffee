$ ->
  $(document).on 'click', '.change_current_bug_state', ->
    $('#current_bug_state, #change_state_form').toggle()

  $(document).on 'click', '.change_current_bug_editor', ->
    $('#current_bug_editor, #change_editor_form').toggle()

  $(document).on 'click', '.change_current_bug_committer', ->
    $('#current_bug_committer, #change_committer_form').toggle()

  $(".reset").click (e) ->
    e.preventDefault();
    $(this).closest('form').find("input").val("")
    $(this).closest('form').find("select").val("")

  $("input[name='bug[bug_range]']").click () ->
    if($('input[name="bug[bug_range]"]').prop('checked'))
      $(".bugzilla_max").show()
    else
      $(".bugzilla_max").hide()

  $("#change_state_form").submit (e)->
    e.preventDefault()
    id = $('input[name="id"]').val()
    state = $('#bug_state option:selected').text()
    $.ajax(
      url: "/bugs/" + id
      method: 'PUT'
      data:
        id: id
        bug: 'state': state
      ).done (response) ->
        $('#current_bug_state').html(response.bug.state).append(' &nbsp;<a class="tiny text-muted change_current_bug_state"><em>change</em></a>')
        $('#current_bug_state, #change_state_form').toggle()
        return

  $("#change_editor_form").submit (e)->
    e.preventDefault()
    id = $('input[name="id"]').val()
    editor = $('#bug_editor option:selected').val()
    $.ajax(
      url: "/bugs/" + id
      method: 'PUT'
      data:
        id: id
        bug: 'user_id': editor
    ).done (response) ->
      $('#current_bug_editor').html(response.bug.user_name).append('&nbsp;<a class="tiny text-muted change_current_bug_editor"><em>change</em></a>')
      $('#current_bug_editor, #change_editor_form').toggle()
      return

  $("#change_committer_form").submit (e)->
    e.preventDefault()
    id = $('input[name="id"]').val()
    committer = $('#bug_committer option:selected').val()
    $.ajax(
      url: "/bugs/" + id
      method: 'PUT'
      data:
        id: id
        bug: 'committer_id': committer
    ).done (response) ->
      $('#current_bug_committer').html(response.bug.committer_name).append('&nbsp;<a class="tiny text-muted change_current_bug_committer"><em>change</em></a>')
      $('#current_bug_committer, #change_committer_form').toggle()
      return
