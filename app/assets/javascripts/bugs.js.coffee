$ ->
  $(document).on 'click', '#change_current_bug_state', ->
    $('#current_bug_state, #change_state_form').toggle()

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
        $('#current_bug_state').html(response.bug.state).append('&nbsp;<a class="tiny text-muted" id="change_current_bug_state"><em>change</em></a>')
        $('#current_bug_state, #change_state_form').toggle()
        return
