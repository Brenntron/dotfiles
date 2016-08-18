$ ->

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
        $('alert_rules').removeClass('.success')
        $('alert_rules').addClass('error').append('Please provide correct rule sid')
    }

  $(document).on 'click', '#remove',  ->
    selected = []
    if window.confirm("Are you sure?")
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
            $('.alert_rules').removeClass('error')
            $('.alert_rules').addClass('success').append('Rule '+value+' has been deleted')
            $('.rule_'+value).remove()
        error: (response) ->
          $('.alert_rules').addClass('error').append('Rule '+value+' has not been deleted')
        complete: ->
          setTimeout (->
            $('.alert_rules').hide 'blind', {}, 500
            return
          ), 5000
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

  $('.create').on "click", '.save-rule-btn', (e) ->
    e.preventDefault();
    form = $(this).parents('.legacy_form');
    rule_content = form.find('textarea[name="rule[rule_content]"]').val();
    rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
    data = {api_key: 'h93hq@hwo9%@ah!jsh', rule: rule}
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax {
      url: "/api/v1/rules"
      method: 'POST'
      data: data
      headers: headers
      success: (response) ->
        $('.alert_rules').addClass('success').show().html('New rule has been created')
        rule = response.rule
        if rule.sid==null
          version = 'new_rule'
        else
          version = rule.gid+':'+rule.sid+':'+rule.rev
        string = '<tr id='+rule.id+'>'+
          '<td><input type="checkbox" class="rule_check_box" value='+rule.id+'></td>'+
          '<td>'+rule.state+'</td>'+
          '<td>'+version+'</td>'+
          '<td><code>'+rule.message+'</code></td>'+
          '<td class="center">-</td><td class="center">-</td><td class="center">-</td></tr>'
        $('.rules_table tbody').append(string)
        form.parents('.new_rule_form').remove()
      error: (response) ->
        $('.alert_rules').addClass('error').show().html('New rule has not been created')
      complete: ->
        setTimeout (->
          $('.alert_rules').hide 'blind', {}, 500
          return
        ), 5000
    }

  $('.create').on 'click', '#save_all_rules', ->
    $('.create .legacy_form').each ->
      _this = $(this)
      rule_content = $(this).find('textarea[name="rule[rule_content]"]').val()
      rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
      data = {api_key: 'h93hq@hwo9%@ah!jsh', rule: rule}
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax {
        url: "/api/v1/rules"
        method: 'POST'
        data: data
        headers: headers
        success: (response) ->
          $('.alert_rules').addClass('success').show().append('<p>New rule has been created</p>')
          rule = response.rule
          if rule.sid==null
            version = 'new_rule'
          else
            version = rule.gid+':'+rule.sid+':'+rule.rev
          string = '<tr id='+rule.id+'>'+
            '<td><input type="checkbox" class="rule_check_box" value='+rule.id+'></td>'+
            '<td>'+rule.state+'</td>'+
            '<td>'+version+'</td>'+
            '<td><code>'+rule.message+'</code></td>'+
            '<td class="center">-</td><td class="center">-</td><td class="center">-</td></tr>'
          $('.rules_table tbody').append(string)
          _this.parents('.new_rule_form').remove()
        error: (response) ->
          $('.alert_rules').removeClass('success')
          $('.alert_rules').addClass('error').show().html('New rule has not been created')
        complete: ->
          setTimeout (->
            $('.alert_rules').hide 'blind', {}, 500
            return
          ), 5000
      }

  $('.edit').on "click", '.update-rule-btn', (e) ->
    e.preventDefault();
    form = $(this).parents('.legacy_form')
    rule_content = form.find('textarea[name="rule[rule_content]"]').val()
    id = form.find('input[name="rule_id"]').val()
    rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
    data = {api_key: 'h93hq@hwo9%@ah!jsh', id: id, rule: rule}
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax {
      url: "/api/v1/rules/"+id
      method: 'PUT'
      data: data
      headers: headers
      success: (response) ->
        $('.alert_rules').addClass('success').show().html('Rule has been updated')
        form.hide()
        $('.rule_'+id).append('<div class="col-xs-12 alert_edit">Rule has been updated</div>')
      error: (response) ->
        $('.alert_rules').addClass('error').show().html('Rule has not been updated')
      complete: ->
        setTimeout (->
          $('.alert_rules').hide 'blind', {}, 500
          $('.alert_edit').remove()
          form.show()
          return
        ), 5000
    }