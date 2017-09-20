
window.bug_resolve =(tag) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  bugzilla_id = $('.bugzilla_id').text()
  $.ajax {
    url: '/api/v1/bugs/' + bugzilla_id + '/resolve'
    method: 'patch'
    headers: headers
    success: (response) ->
      location.reload()
    error: (response) ->
      alert ("could not take this bug" + response)
      location.reload()
  }

$ ->
  $('#bugzilla_popover_state').popover();
  $('.active').show();
  $('.hidden').hide();

  $('#bug_state').change (e) ->
    $("#state_comment_row").show()
    $("#state_comment").prop('required',true);

  $(".take-bug").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $(this).data("id")
    $("#take-bug-"+id).hide()
    $("#bug-wait-"+id).show()
    $('#loading_image').removeClass('hidden').show()
    $.ajax {
      url: '/api/v1/bugs/'+id+'/subscribe'
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("could not take this bug" + response)
        location.reload()
    }

  $(".return-bug").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $(this).data("id")
    $("#return-bug-"+id).hide()
    $("#bug-wait-"+id).show()
    $('#loading_image').removeClass('hidden').show()
    $.ajax {
      url: '/api/v1/bugs/'+id+'/unsubscribe'
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("cant return this bug." + response)
        location.reload()
    }

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
      $('.progress-bar').css('width', '1%')
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
              $('.progress_group').hide()
              $('#progress').html 'Done'
            if response < 0
              clearInterval(progresspump)
              $('.progress_group').hide()
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
        json = $.parseJSON(response)
        if (json.error)

          message = "There was a problem attempting to import this bug:"
          message += json.error

          $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
        else
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
      json = $.parseJSON(response)
      if (json.error)
        message = "There was a problem attempting to synch this bug:"
        message += json.error
        $('.resynch_bug').show()
        $('#loading_image').hide()
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(message)
      else
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
            if ("bugzilla_id" of response)
              alert("Removed bug " + response.bugzilla_id + " from analyst-console")
            else
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
    bid = $('input[name="bug_id"]').val()
    bug_state = $('#bug_state').val()
    if bug_state == "PENDING"
      $('.edit-bug').hide()
      $('#synching_bug_form_button').removeClass('hidden').show()
      $.ajax(
        url: '/api/v1/bugs/import/' + bid
        method: 'GET'
        headers: headers
      ).done (response) ->
        json = $.parseJSON(response)

        if (json.error)
          message = "There was a problem attempting to synch this bug:"
          message += json.error
          $("#alert_message").addClass('alert alert-danger alert-dismissable').append(message)
        else
          if(json.import_report.total_changes == 0)
            state_comment = $("#state_comment").val()
            data = $('.edit_bug').serialize()
            if state_comment
              data = data + "&bug%5Bstate%5Fcomment%5D=" + encodeURIComponent(state_comment)
            $('#synching_bug_form_button').hide()
            $('#saving_bug').removeClass('hidden').show()
            $.ajax(
              url: '/api/v1/bugs/' + bid
              method: 'PUT'
              headers: headers
              data: data
              success: (response) ->
                window.location.reload()
              error: (response) ->
                alert(response.responseText)
                window.location.reload()
            , this)
          else
            if(!alert("There have been #{json.import_report.total_changes} changes to this bug after synching.  You should review the bug, rules, attachments, notes, tags, and references before changing the bug state"))
              window.location.reload()
    else
      state_comment = $("#state_comment").val()
      data = $('.edit_bug').serialize()
      if state_comment
        data = data + "&bug%5Bstate%5Fcomment%5D=" + encodeURIComponent(state_comment)
      $('.edit-bug').hide()
      $('#saving_bug').removeClass('hidden').show()
      $.ajax(
        url: '/api/v1/bugs/' + bid
        method: 'PUT'
        headers: headers
        data: data
        success: (response) ->
          window.location.reload()
        error: (response) ->
          alert(response.responseText)
          window.location.reload()
      , this)






  $('.new_bug').submit (e) ->
    e.preventDefault()
    $('.edit-bug').prop('disabled', true)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    data = $('.new_bug').serialize()
    $('.edit-bug').hide()
    $('#saving_bug').removeClass('hidden').show()
    $.ajax(
      url: '/api/v1/bugs/'
      method: 'POST'
      headers: headers
      data: data
      success: (response) ->
        location.replace('/bugs/' + response['id'])
      error: (response) ->
        alert(response.responseText)
        location.reload()
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

  $("#add-bug-ref-btn").on 'click', ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    bug_id = $('#select-to-edit').attr('bug_id')
    ref_id = $('#add-bug-ref-type-name').val()
    ref_data = $('#add-bug-ref-data').val()
    $.ajax(
      url: '/api/v1/bugs/' + bug_id + '/addref'
      method: 'POST'
      data: { ref_type_name: ref_id, ref_data: ref_data }
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        notice_html = "<p>Something went wrong.</p>"
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      , this)


  $("#add-bug-exploit-btn").on 'click', ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    bug_id = $('#select-to-edit').attr('bug_id')
    ref_id = $('#add-bug-exploit-ref-id').val()
    exploit_type_id = $('#add-bug-exploit-type-id').val()
    attach_id = $('#add-bug-exploit-attach-id').val()
    exploit_data = $('#add-bug-exploit-data').val()
    $.ajax(
      url: '/api/v1/bugs/' + bug_id + '/addexploit'
      method: 'POST'
      data:
        {
          reference_id: ref_id,
          exploit_type_id: exploit_type_id,
          attachment_id: attach_id,
          exploit_data: exploit_data
        }
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        notice_html = "<p>Something went wrong.</p>"
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      , this)


  $ ->
    $('[data-toggle="tooltip"]').tooltip()
    return


namespace 'AC.Bugs', (exports) ->

  exports.monitorJobQueue = () ->
    AC.Bugs.rebuildJobQueue()
    setInterval ->
      tab = $('.nav-tabs .active').text()
      if tab == 'Jobs'
        AC.Bugs.rebuildJobQueue()
    , 20000
  exports.buildJobRows = (data) ->
    rows = []
    for job in data
       rows.push "<tr data-task-id='#{job['id']}' class='#{AC.Bugs.buildTaskCssClass(job)}'>#{AC.Bugs.buildSuccessfulColumn(job)}#{AC.Bugs.buildTypeColumn(job)}#{AC.Bugs.buildDetailsColumn(job)}#{AC.Bugs.buildUserColumn(job)}#{AC.Bugs.buildCreatedColumn(job)}</tr>"
    if rows.length > 0
      content = rows.join("")
    else
      content = "<tr><td colspan='7' class='center text-muted'><em>No tasks for this bug.</em></td></tr>"
    return content
  exports.buildStatusIcon = (data) ->
    if data['completed'] == false
      return "<span class='glyphicon glyphicon-minus'></span>"
    if data['failed'] == true
      return "<span class='glyphicon glyphicon-remove'></span>"
    return "<span class='glyphicon glyphicon-ok'></span>"
  exports.buildTaskCssClass = (data) ->
    if data['completed'] == false
      return "task-incomplete"
    if data['failed'] == true
      return "task-fail"
    return "task-success"
  exports.buildSuccessfulColumn = (data) ->
    return "<td class='status-col'>#{AC.Bugs.buildStatusIcon(data)}</td>"
  exports.buildRuleList = (data) ->
    return data['rule_list']
  exports.buildDetailsColumn = (data) ->
    return "<td>#{AC.Bugs.buildRuleList(data)}<div><pre>#{data['result']}</pre></div></td>"
  exports.buildUserColumn = (data) ->
    return "<td class='user-col'>#{data['cvs_username']}</td>"
  exports.buildCreatedColumn = (data) ->
    return "<td>#{data['created_at']}</td>"
  exports.buildTypeColumn = (data) ->
    return "<td class='task-type-col'>#{data['task_type']}</td>"
  exports.rebuildJobQueue = () ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/queue/' + bid
      headers: headers
      method: 'GET'

    ).done (response) ->
      json = $.parseJSON(response)
      if (json.status == "success")
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html("")
        $("#alert_message").removeClass('alert alert-danger alert-dismissable')
        rows = AC.Bugs.buildJobRows(json.data)

        $("#task-log-table tbody").html("")
        $("#task-log-table tbody").html(rows)
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(json.error)