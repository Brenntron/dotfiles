$ ->
  $('.standard_form').hide()

  $(document).on 'click','.rules_check_box', ->
    $(".rule_check_box").prop("checked", $(".rules_check_box").prop("checked"))

  $(document).on 'click','.rules_check_box, .rule_check_box', ->
    selected = []
    allboxes = []
    $('input:checkbox.rule_check_box').each ->
      allboxes.push($(this).val())
      if @checked
        _val = $(this).val()
        selected.push(_val)
    allboxes = $.unique(allboxes)
    $.each allboxes, (i, v) ->
      $('.rule_'+v).removeClass('active').addClass('hidden')
    $.each selected, (i, v) ->
      $('.rule_'+v).removeClass('hidden').addClass('active')

  $('#linkRuleForm').submit (e) ->
    e.preventDefault()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    rule_id = $('#linkRuleForm input[name="sid"]').val()
    bug_id = $('input[name="bug_id"]').val()
    query = bug_id+":"+rule_id
    $.ajax {
      url: "/api/v1/bugs/rules/"+query
      method: 'POST'
      headers: headers
      data: {'api_key': 'h93hq@hwo9%@ah!jsh'}
      success: (response) ->
        window.location.reload()
      error: (response) ->
        alert('Please provide proper rule sid')
    }

  $(document).on 'click', '#remove',  ->
    selected = []
    $('input:checkbox.rule_check_box').each ->
      if @checked
       selected.push($(this).val())
    $.ajax {
      url: "/rules"
      data: { ids: selected }
      type: 'DELETE'
      dataType: 'json'
      success: (response) ->
        $.each selected, (index, value) ->
          $('.rules_table tr#'+value).remove()
      error: (response) ->
        console.log('Error')
    }

  $(document).on 'click', '#test',  ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    bug_id = $('input[name="bug_id"]').val()
    user_id = $('input[name="current_user_id"]').val()
    selected = []
    $('input:checkbox.rule_check_box').each ->
      if @checked
        selected.push($(this).val())
    data = {api_key: 'h93hq@hwo9%@ah!jsh', task: {bugzilla_id: bug_id, rule_array: selected.join(), task_type: "rule", created_by: user_id}}
    $.ajax {
      url: "/api/v1/tasks"
      method: 'POST'
      data: data
      headers: headers
      success: (response) ->
        task = response.task
        d = new Date()
        month = d.getMonth()+1
        day = d.getDate()
        date = month + '/' + day + '/' + d.getFullYear()
        string = '<tr id='+task.id+'><td class="center"><input type="checkbox"></td>'+
          '<td class="center"><input type="checkbox"></td>'+
          '<td>'+task.task_type+'</td><td></td><td></td>'+
          '<td>'+task.result+'</td>'+
            '<td>'+task.user_name+'</td><td>'+date+'</td></tr>'
        $('#jobs-tab table tbody').append(string)
        $('.alert_rules').addClass('success').show().html('Task has been created to test the rule')
      error: (response) ->
        $('.alert_rules').addClass('error').show().html('Task has not been created')
      complete: ->
        setTimeout (->
          $('.alert_rules').hide 'blind', {}, 500
          return
        ), 5000
    }

  $(document).on 'click', '#legacy_btn, #standard_btn', (e) ->
    e.preventDefault()
    $('.legacy_form, #legacy_btn, .standard_form, #standard_btn').toggle()

