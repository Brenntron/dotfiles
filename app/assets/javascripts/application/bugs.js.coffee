window.prepare_escalations =(this_tag) ->
  $('#unlock_escalations_modal').modal('show')

window.bug_resolve =(this_tag) ->
  user_id = $('#resolve-form').find("input[name='user_id']").val()
  committer_id = $('#resolve-form').find("input[name='committer_id']").val()
  summary = $('#resolve-form').find("input[name='summary']").val()
  tag_names = $('#select-to-edit').val() || []
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  bugzilla_id = $('.bugzilla_id').text()

  new_escalation_message = ""
  #switch $('input[name=new_escalation_message]:checked').val()
  #  when 'esc1'
  #    new_escalation_message = $('input[name=new_escalation_message]:checked').parent().text()
  #  when 'esc2'
  new_escalation_message = $('textarea#new_escalation_message_custom').val()


  new_escalation_status = ""
  new_escalation_status = $("#new_escalation_status").val()

  $('#resolve_bug_form_button').hide()
  $('#synching_bug_form_button').hide()
  $('#resolving_bug_form_button').removeClass('hidden').show()
  $('#saving_bug').removeClass('hidden').show()
  $.ajax(
    url: '/api/v1/bugs/import/' + bugzilla_id + '?import_type=status'
    method: 'GET'
    headers: headers
  ).done (response) ->
    json = $.parseJSON(response)

    if (json.error)
      message = "There was a problem attempting to sink this bug:"
      message += json.error
      $("#alert_message").addClass('alert alert-danger alert-dismissable').append(message)
    else
      if(json.import_report.total_changes == 0)
        $.ajax(
          url: '/api/v1/bugs/' + bugzilla_id
          method: 'PUT'
          headers: headers
          data:
            {
              bug:
                {
                  state: "PENDING",
                  state_comment: "Resolved bug",
                  user_id: user_id,
                  committer_id: committer_id,
                  summary: summary,
                  tag_names: tag_names
                }
              escalation:
                {
                  state: new_escalation_status,
                  message: new_escalation_message
                }
            }
          success: (response) ->
            location.reload(true)
          error: (response) ->
            if response.responseText != undefined && response.responseText != ""
              alert(response.responseText)
            location.reload(true)
        , this)
      else
        AC.Bugs.buildStatusReportModal(json.import_report)

window.toggle_liberty =(this_tag, bug_id) ->
  confirmed = true
  if "embargo_on" == this_tag.className
    confirmed = confirm("Are you sure?")

  if (true == confirmed)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/' + bug_id + '/toggle_liberty'
      method: 'PATCH'
      headers: headers
      data: { }
      success: (response) ->
        if "CLEAR" == response
          this_tag.className = "embargo_off"
        else
          this_tag.className = "embargo_on"
    , this)


window.add_bug_ref_show = ->
  $('#add-bug-ref-div').show();
  $('#add-bug-ref-show').hide();
  $('#add-bug-ref-hide').show();

window.add_bug_ref_hide = ->
  $('#add-bug-ref-div').hide();
  $('#add-bug-ref-show').show();
  $('#add-bug-ref-hide').hide();

window.add_bug_exploit_show = ->
  $('#add-bug-exploit-div').show();
  $('#add-bug-exploit-show').hide();
  $('#add-bug-exploit-hide').show();

window.add_bug_exploit_hide = ->
  $('#add-bug-exploit-div').hide();
  $('#add-bug-exploit-show').show();
  $('#add-bug-exploit-hide').hide();

window.ruleShow = (rule) ->
  id = rule.attributes['data-rule'].value
  #switch tabs
  $('#bug_tab a[class= "rules-tab"]').tab 'show'
  #uncheck checkboxes
  $('.rule_check_box').prop 'checked', $('.rules_check_box').prop('checked')
  #check appropriate checkbox
  $('#rule_' + id).prop 'checked', true
  $('.view').removeClass('hidden').addClass('active').show()
  $('.rule_' + id).removeClass('hidden').addClass('active').show()
  return

$ ->

  $("#secure_snort_bug_button").on 'click', (e) ->

    bugzilla_id = $('.bugzilla_id').text()

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    $("#secure_snort_bug_button").hide()
    $("#secure-wait").show()

    $.ajax(
      url: '/api/v1/bugs/set_snort_security/' + bugzilla_id
      method: 'POST'
      data: {snort_secure: 'true'}
      headers: headers
    ).done (response) ->

      json = $.parseJSON(response)
      if (json.status == "error")

        message = "There was a problem:"
        message += json.message

        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
      else
        location.reload()


  $("#declassify_snort_bug_button").on 'click', (e) ->
    bugzilla_id = $('.bugzilla_id').text()

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}

    $("#declassify_snort_bug_button").hide()
    $("#secure-wait").show()

    $.ajax(
      url: '/api/v1/bugs/set_snort_security/' + bugzilla_id
      method: 'POST'
      data: {snort_secure: 'false'}
      headers: headers
    ).done (response) ->

      json = $.parseJSON(response)
      if (json.status == "error")

        message = "There was a problem:"
        message += json.message

        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
      else
        location.reload()



  $('#bugzilla_popover_state').popover();
  $('.active').show();
  $('.hidden').hide();

  $('#bug-form-state-input').change (e) ->
    new_state = $("#bug-form-state-input").val()
    $("#state_comment_row").show()
    $("#state_comment").prop('required',true);
    has_blockers = $("#edit_bug_has_blockers").val()

    if new_state == "PENDING" && has_blockers == "true"
      $("#edit_escalation_new_state").show()
      $("#edit_escalation_new_state").prop('required', true);

      $("#edit_escalation_new_message").show()
      $("#edit_escalation_new_message").prop('required', true);

    if $('#bug-form-product-input').val() == "Escalations"
      $('#state_comment')[0].value = canned_response(new_state)

  canned_response = (bug_state) ->
    responses =
      "FIXED": "Coverage has been updated."
      "COMPLETED": "Coverage has not been updated."
      "LATER": "There is currently not enough information to create coverage at this time. If more information becomes available we will evaluate updating coverage at that point."
      "": ""
    if responses[bug_state] then responses[bug_state] else ''


  $("#save_giblet_search_button").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    giblets = $("#save_giblet_search_field").val()
    $.ajax {
      url: '/api/v1/saved_searches/'
      data: {giblets: giblets}
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("Sorry, you can not take this bug\n" + response.responseJSON.error)
        location.reload()
    }

  $(".take-bug").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $(this).data("id")
    $("#take-bug-"+id).hide()
    $("#bug-wait-"+id).show()
    $('#loading_image').removeClass('hidden').show()
    $.ajax {
      url: '/api/v1/bugs/'+id+'/subscribe'
      data: {committer: false}
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("Sorry, you can not take this bug\n" + response.responseJSON.error)
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
      data: {committer: false}
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("cant return this bug." + response.responseJSON.error)
        location.reload()
    }

  $(".take-bug-committer").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $(this).data("id")
    $("#take-bug-committer-"+id).hide()
    $("#bug-wait-committer-"+id).show()
    $('#loading_image').removeClass('hidden').show()
    $.ajax {
      url: '/api/v1/bugs/'+id+'/subscribe'
      data: {committer: true}
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("Sorry, you can not take this bug\n" + response.responseJSON.error)
        location.reload()
    }

  $(".return-bug-committer").on 'click', (e) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    id = $(this).data("id")
    $("#return-bug-committer-"+id).hide()
    $("#bug-wait-committer-"+id).show()
    $('#loading_image').removeClass('hidden').show()
    $.ajax {
      url: '/api/v1/bugs/'+id+'/unsubscribe'
      data: {committer: true}
      method: 'post'
      headers: headers
      success: (response) ->
        location.reload()
      error: (response) ->
        alert ("cant return this bug." + response.responseJSON.error)
        location.reload()
    }

  $('#relate_by_bug_id_button').on 'click', ->
    bugzilla_id = $('.bugzilla_id').text()
    relate_id = $('#related_bug_id_field').val()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/relate_bug/' + bugzilla_id + '/' + relate_id
      method: 'POST'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.error)

        message = "There was a problem attempting to relate this bug:"
        message += json.error

        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
      else
        product = json.product
        if product == 'Escalations'
          window.location.replace '/escalations/bugs/' + bugzilla_id
        else
          window.location.replace '/bugs/' + bugzilla_id


  $('#find_bugs_by_sid_button').on 'click', ->
    bugzilla_id = $('.bugzilla_id').text()
    sid = $('#search_by_sid_field').val()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/find_bugs_by_sid/' + sid
      method: 'GET'
      headers: headers
    ).done (response) ->
      $("#bugs_from_sid_table tbody").html(rows)
      json = $.parseJSON(response)
      if (json.status == "error")

        message = "There was a problem attempting to find bugs:"
        message += json.message

        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
      else
        rows = []
        bugs = json.data
        for bug in bugs
          bug_summary = bug.summary.replace(/,/g, ', ')
          rows.push "<tr><td>#{bug.id}</td><td>#{bug_summary}</td><td><button class='btn' onclick='AC.Bugs.relateBug(#{bugzilla_id}, #{bug.id})'>Relate</button></td></tr>"

        if rows.length > 0
          content = rows.join()
        else
          content = "<tr><td class='center text-muted'><em>No bugs found with this SID</em></td></tr>"

        $("#sid-search-results tbody").html(content)


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

  $('#button_import_escalation').on 'click', ->
    bid = $('#import_escalation').val()
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
        url: '/escalations/api/v1/escalations/bugs/import/' + bid
        method: 'GET'
        headers: headers
      ).done (response) ->
        json = $.parseJSON(response)
        if (json.error)

          message = "There was a problem attempting to import this bug:"
          message += json.error

          $("#alert_message").addClass('alert alert-danger alert-dismissable').html(message)
        else
          window.location.replace '/escalations/bugs/' + bid


  $('.resync_escalation_button').on 'click', ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $('.resync_escalation_button').hide()
    $('.loading_image').removeClass('hidden').show()
    $.ajax(
      url: '/escalations/api/v1/escalations/bugs/import/' + bid
      method: 'GET'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.error)
        message = "There was a problem attempting to sink this bug:"
        message += json.error
        $('.resync_escalation_button').show()
        $('.loading_image').hide()
        $("#alert_message").addClass('alert alert-danger alert-dismissable').append(message)
      else
        window.location.replace '/escalations/bugs/' + bid


  $('.resync_bug_button').on 'click', ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $('.resync_bug_button').hide()
    $('.loading_image').removeClass('hidden').show()
    $.ajax(
      url: '/api/v1/bugs/import/' + bid
      method: 'GET'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.error)
        message = "There was a problem attempting to sink this bug:"
        message += json.error
        $('.resync_bug_button').show()
        $('.loading_image').hide()
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


  $('#import_escalation').keyup (e) ->
    bid = $('#import_escalation').val()
    if (bid != "")
      $('#button_import_escalation').prop('disabled', false)
      return false
    else
      $('#button_import_escalation').prop('disabled', true)
      return false

  $('#import_escalation').keypress (e) ->
    if (e.which == 13)
      $('button#button_import_escalation').click()
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
          url: '/api/v1/bugs/import/' + bid + '?import_type=status'
          method: 'GET'
          headers: headers
        ).done (response) ->
          json = $.parseJSON(response)

          if (json.error)
            message = "There was a problem attempting to sink this bug:"
            message += json.error
            $("#alert_message").addClass('alert alert-danger alert-dismissable').append(message)
          else

            if(json.import_report.total_changes == 0)
              state_comment = $("#state_comment").val()
              escalation_comment = $("#escalation_new_message_field").val()
              escalation_state = $("#escalation_new_state").val()
              data = $('.edit_bug').serialize()
              if state_comment
                data = data + "&bug%5Bstate%5Fcomment%5D=" + encodeURIComponent(state_comment)
              if escalation_comment
                data = data + "&escalation%5Bmessage%5D=" + encodeURIComponent(escalation_comment)
              if escalation_state
                data = data + "&escalation%5Bstate%5D=" + encodeURIComponent(escalation_state)
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
              AC.Bugs.buildStatusReportModal(json.import_report)
              #alert("There are #{json.import_report.total_changes} changes outstanding on this bug.  You should sink and review the changes before attempting this action")
              #window.location.reload()
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


  $('.new_research_bug').submit (e) ->
    e.preventDefault()
    $('.edit-bug').prop('disabled', true)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    data = $('.new_research_bug').serialize()
    $('.edit-bug').hide()
    $('#saving_bug').removeClass('hidden').show()
    $.ajax(
      url: '/api/v1/bugs/research'
      method: 'POST'
      headers: headers
      data: data
      success: (response) ->
        location.replace('/bugs/' + response['id'])
      error: (response) ->
        alert(response.responseText)
        location.reload()
    , this)


  $('.new_escalation_bug').submit (e) ->
    e.preventDefault()
    $('.edit-bug').prop('disabled', true)
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    data = $('.new_escalation_bug').serialize()
    $('.edit-bug').hide()
    $('#saving_bug').removeClass('hidden').show()
    $.ajax(
      url: '/escalations/api/v1/bugs/escalation'
      method: 'POST'
      headers: headers
      data: data
      success: (response) ->
        location.replace('/escalations/bugs/' + response['id'])
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

  createGibletOptions = ->
    tags = $('#giblet_list')[0]
    if tags
      tag_list = tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options


  $('#selectize-giblets').selectize {
    persist: false,
    create: (input) ->
      {name: input}
    maxOptions: 10000
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createGibletOptions()
  }

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
  createSelectOptionsForWhiteboard = ->
    whiteboards = $('#whiteboard_list')[0]
    if whiteboards
      whiteboard_list = whiteboards.value
      array = whiteboard_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  $('#whiteboard-select-to-edit').selectize {
    create: (input) ->
      {name: input}
    persist: false
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptionsForWhiteboard()
    onItemAdd: (item) ->
      bug_id = $('#select-to-edit').attr('bug_id')
      $.ajax(
        url: bug_id + '/add_whiteboard'
        method: 'POST'
        data: {bug: {id: bug_id, whiteboard_name: item}}
        success: (response) ->
          notice_html = "<p>#{item} has been added.</p>"
          $("#alert_message").addClass('alert alert-info alert-dismissable').append(notice_html)
          window.location.reload()
        error: (response) ->
          notice_html = "<p>Something went wrong.</p>"
          $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      , this)

    onItemRemove: (item) ->
      bug_id = $('#whiteboard-select-to-edit').attr('bug_id')
      $.ajax(
        url: bug_id + '/remove_whiteboard'
        method: 'PATCH'
        data: {bug: {id: bug_id, whiteboard_name: item}}
        success: (response) ->
          notice_html = "<p>#{item} has been removed.</p>"
          $("#alert_message").addClass('alert alert-info alert-dismissable').append(notice_html)
          window.location.reload()
        error: (response) ->
          notice_html = "<p>Something went wrong.</p>"
          $("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      , this)

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
    text = this.textContent
    which = $(this).data('rulealert')
    if 'untested' == text
      $('.'+which).hide()
    else
      $('.'+which).toggle()

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


  $(".close-status-report").on 'click', ->
    $("#reloading_page").modal({backdrop: 'static', keyboard: false})
    window.location.reload()

namespace 'AC.Bugs', (exports) ->
  exports.reopenBug = (bug_id, relate_id, user_id, committer_id, summary) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/' + relate_id
      method: 'put'
      headers: headers
      data:
          {
            bug:
               {
                 summary: summary,
                 user_id: user_id,
                 committer_id: committer_id,
                 state:"REOPENED",
                 state_comment:  "Reopened bug via related bug: "+ bug_id
               }
          }

    ).done (response) ->
      #NOTE: ok this is weird i know v1/bugs returns a bug not a json response and rather than fix it all over the code im going to use a regex to pick out the product
      if (response)
        product = /"product"=>"Escalations"/.exec(response)
        if (product)
          window.location.replace '/escalations/bugs/' + bug_id
        else
          window.location.replace '/bugs/' + bug_id
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html("Could not reopen bug")

  exports.removeRelatedBug = (bug_id, relate_id) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/remove_bug_relation/' + bug_id + '/' + relate_id
      method: 'DELETE'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.status == "success")
        product = json.product
        if product == 'Escalations'
          window.location.replace '/escalations/bugs/' + bug_id
        else
          window.location.replace '/bugs/' + bug_id
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(json.error)

  exports.relateBug = (bug_id, relate_id) ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/relate_bug/' + bug_id + '/' + relate_id
      method: 'POST'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.status == "success")
        product = json.product
        if product == 'Escalations'
          window.location.replace '/escalations/bugs/' + bug_id
        else
          window.location.replace '/bugs/' + bug_id
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(json.error)

  exports.deleteSavedSearch = (saved_search_id) ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/saved_searches/' + saved_search_id
      method: 'DELETE'
      headers: headers
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.status == "success")
        $("#saved_search_#{saved_search_id}").remove()
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(json.error)
  exports.buildStatusReportModal = (status_report) ->

    if Object.keys(status_report.changed_bug_columns).length > 0
      bug_change_content = "<h5><b>These Bug attributes will be changed as a result of sinking:</b></h5>"
      #for bug_change in status_report.changed_bug_columns
      #  bug_change_content += "&nbsp;&nbsp;&nbsp;&nbsp;#{bug_change[0]} = #{bug_change[1]}<br />"
      bug_change_content += "<table style='width:100%;'><tr><th>attribute</th><th>before</th><th>after</th><tbody>"
      for k,v of status_report.changed_bug_columns
        bug_change_content += "<tr><td>#{k}</td><td><span style='color: green;'>#{v[0]}</span></td><td><span style='color: red;'>#{v[1]}</span></td></tr>"
      $("#status_bug_changes").html(bug_change_content)
      bug_change_content += "</tbody></table>"
    if status_report.new_rules.length > 0
      new_rules_content = "<h5><b>New Rules Detected in Bugzilla not found in Analyst Console:</b></h5>"
      for new_rule in status_report.new_rules
        new_rules_content += "&nbsp;&nbsp;&nbsp;&nbsp;#{new_rule}<br />"
      $('#status_new_rules').html(new_rules_content)

    if status_report.new_attachments.length > 0
      new_attachments_content = "<h5><b>New Attachments Detected in Bugzilla not found in Analyst Console:</b></h5>"
      for new_attachment in status_report.new_attachments
        new_attachments_content += "&nbsp;&nbsp;&nbsp;&nbsp;#{new_attachment}<br />"
      $('#status_new_attachments').html(new_attachments_content)

    if status_report.new_notes > 0
      new_notes_content = "<h5><b>New Comments under the History tab</b></h5>"
      new_notes_content += "&nbsp;&nbsp;&nbsp;&nbsp;There are #{status_report.new_notes} new notes/comments detected."
      new_notes_content += "<br />&nbsp;&nbsp;&nbsp;&nbsp;<i>(content not shown for purposes of brevity, after sinking look under History tab to see new comments)</i>"
      $('#status_new_notes').html(new_notes_content)

    if status_report.new_tags.length > 0
      new_tags_content = "<h5><b>New Tags in Bugzilla not found in Analyst Console:</b></h5>"
      for new_tag in status_report.new_tags
        new_tags_content += "&nbsp;&nbsp;&nbsp;&nbsp;#{new_tag}<br />"
      $('#status_new_tags').html(new_tags_content)

    if status_report.new_refs.length > 0
      new_refs_content = "<h5><b>New Refs in Bugzilla not found in Analyst Console:</b></h5>"
      for new_ref in status_report.new_refs
        new_refs_content += "&nbsp;&nbsp;&nbsp;&nbsp;#{new_ref}<br />"
      $('#status_new_refs').html(new_refs_content)


    $('#status_report').modal({backdrop: 'static', keyboard: false})


  exports.monitorJobQueue = () ->
    AC.Bugs.rebuildAllTabs()
    setInterval ->
      AC.Bugs.rebuildAllTabs()
    , 50000


  exports.rebuildAllTabs = () ->
    bid = $('.bugzilla_id').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/api/v1/bugs/tabs/' + bid
      headers: headers
      method: 'GET'
    ).done (response) ->
      json = $.parseJSON(response)
      if (json.status == "success")
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html("")
        $("#alert_message").removeClass('alert alert-danger alert-dismissable')
        ##handle alerts tab
        alerts_json = json.alerts_tab
        rows = AC.Bugs.buildAlertRows(alerts_json)
        $("#alerts-table tbody").html(rows)
        ##handle rules tab
        rules_json = json.rules_tab
        AC.Bugs.buildRulesRows(rules_json)
        ##handle attachments tab
        attachments_json = json.attachments_tab
        AC.Bugs.buildAttachmentsRows(attachments_json)
        ##handle job queue tab
        job_queue_json = json.jobs_tab
        open_jobs = json.open_jobs_count
        if open_jobs == 0
          $(".jobs-tab").html("Jobs")
        else
          $(".jobs-tab").html("Jobs (#{open_jobs})")
        rows = AC.Bugs.buildJobRows(job_queue_json)
        $("#task-log-table tbody").html("")
        $("#task-log-table tbody").html(rows)
      else
        $("#alert_message").addClass('alert alert-danger alert-dismissable').html(json.error)

  exports.buildAlertRows = (data) ->
    rows = []
    alerts = data.alerts
    for alert in alerts
      rows.push "<tr>#{AC.Bugs.buildAlertAttachment(alert)}#{AC.Bugs.buildAlertName(alert)}#{AC.Bugs.buildAlertPcaps(alert)}</tr>"
    if rows.length > 0
      content = rows.join("")
    else
      content = "<tr><td colspan='7' class='center text-muted'><em>No alerts for this bug.</em></td></tr>"
    return content

  exports.buildAlertAttachment = (data) ->
    return "<td><code><a href='#{data.direct_upload_url}' target='_blank'>#{data.file_name}</a></code></td>"
  exports.buildAlertName = (data) ->
    return "<td><table class='local-alerts-table'>#{AC.Bugs.buildAlertNameTable(data)}</table></td>"
  exports.buildAlertNameTable = (data) ->
    rows = []
    i = 1
    content = ""
    rules = data.rules
    for rule in rules
      rows.push "<tr class='#{rule.alert_css_class}'><td class='alert-status-col'>#{rule.alert_status}</td><td><strong>#{rule.sid_colon_format} #{i}</strong> #{rule.message}</td></tr>"
      i = i + 1

    if rows.length > 0
      content = rows.join("")
    return content
  exports.buildAlertPcaps = (data) ->
    content = "<td>"
    if data.pcap_alerts.length > 0
      content += "<table class='table-condensed small pcap-alerts-table'>"
      rows = []

      for pcap_alert in data.pcap_alerts
         rows.push "<tr><td class='sid-col'><a id='rule-link' class='blue' onclick='ruleShow(this);' data-rule='#{pcap_alert.rule_id}'><strong>#{pcap_alert.sid_colon_format}</strong></a></td><td class='content-col'><strong>#{pcap_alert.message}</strong></td></tr>"
      content += rows.join("")
      content = content + "</table>"
    else
      content += "<p>No alerts</p>"
    content = content + "</td>"

    return content

  exports.buildRulesRows = (data) ->
    for rule in data
      if $("#rule_count_#{rule.id}").length != 0
        if rule.tested == true
          $("#tested_rule_#{rule.id}").html("<span class='glyphicon glyphicon-ok' title='#{rule.svn_output}'></span>")
          $('[data-toggle="tooltip"]').tooltip();
          $("#rule_count_#{rule.id}").html(rule.alert_count)
        else
          $("#tested_rule_#{rule.id}").html("<span class='glyphicon glyphicon-minus'></span>")
          $("#rule_count_#{rule.id}").html("untested")
        for alert in rule.alerts
          $("#rule_#{rule.id}_att_#{alert.pcap_id}").removeClass();
          if 'alerted' == alert.alert_status
            $("#rule_#{rule.id}_att_#{alert.pcap_id}").html("Alerted")
            $("#rule_#{rule.id}_att_#{alert.pcap_id}").addClass('alerted')
          else
            $("#rule_#{rule.id}_att_#{alert.pcap_id}").html("No Alert")
            $("#rule_#{rule.id}_att_#{alert.pcap_id}").addClass('no_alert')

  exports.buildAttachmentsRows = (data) ->
    for attachment in data
      if $("#attachment_count_#{attachment.id}").length != 0
        $("#attachment_count_#{attachment.id}").html(attachment.alert_count)

        if attachment.pcap_alerts.length > 0 && $("#attachment_#{attachment.id}").length == 0

          content = "<tr style='display:none;' id='attachment_#{attachment.id}'><td></td><td colspan=2><table class='table-condensed small'>"
          for pcap in attachment.pcap_alerts
            content += "<tr><td class='blue'>#{pcap.sid_colon_format}</td><td><strong>#{pcap.message}</strong></td></tr>"
          content += "</table></td></tr>"
          #alert(content)
          $("#attachment_base_#{attachment.id}").after(content);


  #Rebuild Job Queue
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
    safe_result = $('<div/>').text(data['result']).html()
    return "<td>#{AC.Bugs.buildRuleList(data)}<div><pre>#{safe_result}</pre></div></td>"
  exports.buildUserColumn = (data) ->
    return "<td class='user-col'>#{data['cvs_username']}</td>"
  exports.buildCreatedColumn = (data) ->
    return "<td>#{data['created_at']}</td>"
  exports.buildTypeColumn = (data) ->
    return "<td class='task-type-col'>#{data['task_type']}</td>"
