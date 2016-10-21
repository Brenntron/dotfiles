$ ->

  $('.edit-summary').on 'click', ->
    $('.edit-summary-field').toggle()

  $('#bug_tab a:first').tab('show')

  $('#import_bug').keypress (e) ->
    if (e.which == 13)
      $('button#button_import').click();
      return false;

  $(document).on 'click', '.change_current_bug_state', ->
    $('#current_bug_state, #change_state_form').toggle()

  $(document).on 'click', '.change_current_bug_editor', ->
    $('#current_bug_editor, #change_editor_form').toggle()

  $(document).on 'click', '.change_current_bug_committer', ->
    $('#current_bug_committer, #change_committer_form').toggle()

  $('.delete_bug').on 'click', ->
    id = $(this).parents('tr').attr('id')
    id = id.slice(id.indexOf("_")+1, id.length)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    if window.confirm("Are you sure?")
      $.ajax {
        url: '/api/v1/bugs/'+id
        method: 'delete'
        headers: headers
        data: {api_key: 'h93hq@hwo9%@ah!jsh'}
        success: (response) ->
          window.location.reload()
        error: (response) ->
          alert 'Could not delete the bug'
      }

  $('.back_btn').click ->
    window.location.replace('/bugs')

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


  createSelectOptions = ->
    tags = $('#tag_list')[0]
    if tags
      tag_list= tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  $('#select-to-new').selectize {
    persist: false,
    create: (input) ->
      {name: input}
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptions()

  }

  $('#select-to-edit').selectize {
    create: (input) ->
      {name: input}
    persist: false
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptions()
    onItemAdd: (item) ->
      bug_id = $('#select-to-edit').attr('bug_id')
      $.ajax(
        url: bug_id + '/add_tag'
        method: 'POST'
        data: {bug: {id: bug_id, tag_name: item}}
        success: (response) ->
          notice_html = "<p>#{item} has been added.</p>"
          $("#alert_message").addClass('alert alert-info alert-dismissable').append(notice_html)
          window.location.reload()
        error: (response) ->
          notice_html = "<p>Something went wrong.</p>"
          $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      ,this)

    onItemRemove: (item) ->
      bug_id = $('#select-to-edit').attr('bug_id')
      $.ajax(
        url: bug_id + '/remove_tag'
        method: 'PATCH'
        data: {bug: {id: bug_id, tag_name: item}}
        success: (response) ->
          notice_html = "<p>#{item} has been removed.</p>"
          $("#alert_message").addClass('alert alert-info alert-dismissable').append(notice_html)
          window.location.reload()
        error: (response) ->
          notice_html = "<p>Something went wrong.</p>"
          $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      ,this)


  }


