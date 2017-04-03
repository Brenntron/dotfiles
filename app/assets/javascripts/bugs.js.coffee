$ ->
  $('.active').show();
  $('.hidden').hide();

  $('#button_import').on 'click', ->

    bid = $('#import_bug').val()
    if (bid == "")
      alert("Please enter a sid to import.")
      return false
    else if isNaN(bid)
      alert("Your sid is not a number.")
      return false
    else
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      id = $('input[name="bug_name"]').val()
      current_user = $(".current_user").html()
      ### update the progress bar width ###
      $('.progress_group').show()
      $('.progress-bar').css('width', '10%')
      ### and display the numeric value ###
      $('.progress-bar').html('10%')
      progresspump = setInterval(( ->
        ### query the completion percentage from the server ###
        $.ajax {
          url: '/api/v1/events/update-progress'
          method: 'get'
          headers: headers
          data:
            description: $('input[name="token"]').val()
            user: current_user
            id: id
          success: (response) ->
            ### update the progress bar width ###
            $('.progress-bar').css('width', response + '%')
            ### and display the numeric value ###
            $('.progress-bar').html(response + '%')
            ### test to see if the job has completed ###
            if response > 99.999
              clearInterval(progresspump)
              $('#progress').html 'Done'
          error: (response) ->
            clearInterval(progresspump)
            $('.progress-bar').html 'Done'
        }
      ), 1000)
      $.ajax(
        url: '/api/v1/bugs/import/' + bid
        method: 'GET'
        headers: headers
      ).done (response) ->
        window.location.replace '/bugs/' + bid

  $('#resynch_bug').on 'click', ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $('.resynch_bug').hide()
    $('#loading_image').removeClass('hidden').show()
    $.ajax(
      url: '/api/v1/bugs/import/' + bid
      method: 'GET'
      headers: headers
    ).done (response) ->
      window.location.replace '/bugs/' + bid


  $('#bug_tab a:first').tab('show')

  $('#import_bug').keyup (e) ->
    bid = $('#import_bug').val()
    if (bid != "")
      $('#button_import').prop('disabled', false)
      return false
    else
      $('#button_import').prop('disabled', true)
      return false

  $('#import_bug').keypress (e) ->
    if (e.which == 13)
      $('button#button_import').click()
      return false


  $('.delete_bug').on 'click', ->
    id = $(this).parents('tr').attr('id')
    id = id.slice(id.indexOf("_") + 1, id.length)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    if window.confirm("Are you sure you want to remove this bug from Analyst Console?")
      $.ajax {
        url: '/api/v1/bugs/' + id
        method: 'delete'
        headers: headers
        success: (response) ->
          if(typeof response != 'undefined')
            alert(response.error + " \n" + response.message)
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


  $('.edit_bug').submit (e) ->
    e.preventDefault()
    $('.edit-bug').prop('disabled', true)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $('input[name="bug_id"]').val()
    data = $('.edit_bug').serialize()
    $.ajax(
      url: '/api/v1/bugs/' + id
      method: 'PUT'
      headers: headers
      data: data
      success: (response) ->
        location.reload()
      error: (response) ->
        alert(response.responseText)
    , this)


  $('.new_bug').submit (e) ->
    e.preventDefault()
    $('.edit-bug').prop('disabled', true)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    data = $('.new_bug').serialize()
    $.ajax(
      url: '/api/v1/bugs/'
      method: 'POST'
      headers: headers
      data: data
      success: (response) ->
        location.replace('/bugs/' + response['id'])
      error: (response) ->
        alert(response.responseText)
    , this)


  createSelectOptions = ->
    tags = $('#tag_list')[0]
    if tags
      tag_list = tags.value
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
      , this)

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
      , this)


  }

  $(".rulealert-toggle").on 'click', ->
    which = $(this).data('rulealert');
    $('.'+which).toggle();


  $ ->
    $('[data-toggle="tooltip"]').tooltip()
    return


