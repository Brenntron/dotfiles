$ ->
  $('.rule-toolbar').click ->
    tab = $(this).attr('id')
    isSelected = false
    selected = []
    $('input:checkbox.rule_check_box').each ->
      if @checked
        isSelected = true
        selected.push($(this).val())
    if isSelected or tab in ['overview','create']
      switch(tab)
        when 'test'
          headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
          bug_id = $('input[name="bug_id"]').val()
          user_id = $('input[name="current_user_id"]').val()
          data = {task: {bugzilla_id: bug_id, rule_array: selected.join(), task_type: "rule", created_by: user_id}}
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
        when 'remove'
          if window.confirm("Are you sure?")
            $.ajax {
              url: "/rules"
              data: { ids: selected }
              type: 'DELETE'
              dataType: 'json'
              success: (response) ->
                $.each selected, (index, value) ->
                  $('.rules_table tr#'+value).remove()
                  $('.alert_rules').removeClass('error')
                  $('.alert_rules').addClass('success').append('Rule '+value+' has been deleted\n')
                  $('.rule_'+value).remove()
              error: (response) ->
                $('.alert_rules').addClass('error').append('Rule '+value+' has not been deleted\n')
              complete: ->
                setTimeout (->
                  $('.alert_rules').hide 'blind', {}, 500
                  return
                ), 5000
            }
        else
          $('.row.active').addClass('hidden').removeClass 'active'
          $('.' + tab).addClass('active').removeClass 'hidden'
          $('.active').show()
          $('.hidden').hide()
          $('.standard_form').hide()
    else
      alert("please select something")

  $('.diff').find('br').remove()

  $(document).on 'click', '#legacy_btn, #standard_btn', (e) ->
    e.preventDefault()
    $('.legacy_form, #legacy_btn, .standard_form, #standard_btn').toggle()

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

  $(document).on 'change', '.scratch_connection, .connection', ->
    form = $(this).parents('.standard_form');
    if $('.scratch_connection').is(":checked")
      $('.connectionForm').prop('disabled', true)
      form.find('.scratch_connection_text').prop('disabled', false)
    else
      $('.connectionForm').prop('disabled', false)
      form.find('.scratch_connection_text').prop('disabled', true)

  $(document).on 'change', '.scratch_flow, .flow', ->
    form = $(this).parents('.standard_form')
    if $('.scratch_flow').is(":checked")
      $('.flow_form').prop('disabled', true)
      form.find('.scratch_flow_text').prop('disabled', false)
    else
      $('.flow_form').prop('disabled', false)
      form.find('.scratch_flow_text').prop('disabled', true)

  $(document).on 'change', '.scratch_metadata, .metadata', ->
    form = $(this).parents('.standard_form')
    if $('.scratch_metadata').is(":checked")
      $('.metadata_form').prop('disabled', true)
      form.find('.scratch_metadata_text').prop('disabled', false)
    else
      $('.metadata_form').prop('disabled', false)
      form.find('.scratch_metadata_text').prop('disabled', true)

  $('.create').on "click", '.save-rule-btn', (e) ->
    e.preventDefault()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    if $('.legacy_form').is(":visible")
      form = $(this).parents('.legacy_form');
      rule_contents = form.find('textarea[name="rule[rule_content]"]').val()
      contents_arr = rule_contents.split('\n')
      contents_arr.forEach (rule_content) ->
        rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
        data = { rule: rule}
        $.ajax {
          url: "/api/v1/rules"
          method: 'POST'
          data: data
          headers: headers
          success: (response) ->
            $('.alert_rules').removeClass('error')
            $('.alert_rules').addClass('success').show().append('<p>New rule has been created\n</p>')
          error: (response) ->
            $('.alert_rules').removeClass('success')
            $('.alert_rules').addClass('error').show().append('New rule has not been created\n')
          complete: ->
            $(document).ajaxStop ->
              location.reload true
        }
    else if $('.standard_form').is(":visible")
      form = $(this).parents('.standard_form')
      msg = form.find('input[name="rule[message]"]').val()
      msg = '(msg:"' + msg + '";'
      connection = ""
      form.find('input[name="rule[connection][]"], select[name="rule[connection][]"]').each ->
        if $(this).is(":enabled")
          connection = connection + $(this).val() + " "
      flow = "flow:"
      form.find('input[name="rule[flow][]"], select[name="rule[flow][]"]').each ->
        if $(this).is(":enabled")
          flow = flow + $(this).val() + ","
      flow = flow.replace(/,([^,]*)$/,'$1') + ";"
      detection = form.find('textarea[name="rule[detection]"]').val()
      metadata = "metadata:"
      form.find('input[name="rule[metadata][]"], select[name="rule[metadata][]"]').each ->
        if $(this).is(":enabled")
          if ($(this).is('input') && $(this).is(':checked')) || $(this).is('input[type="text"]')
            metadata = metadata + " " + $(this).val() + ","
          else if $(this).is('select')
            metadata = metadata + " " + $(this).val() + ","
      metadata = metadata.replace(/,([^,]*)$/,'$1') + ";"
      class_type = "classtype:" + form.find('select[name="rule[class_type]"]').val()
      ref_types = []
      ref_values = []
      references = ""
      form.find('input[name="rule[reference][][reference_data]"]').each ->
        ref_values.push($(this).val())
      form.find('select[name="rule[reference][][reference_type_id]"], input[name="rule[reference][][reference_type_id]"]').each ->
        ref_types.push($(this).val())
      i = 0
      ref_types.forEach (item) ->
        references = references + "reference:" + item + "," + ref_values[i] + "; "
        i = i + 1
      rule_content = connection + msg + flow + detection + ";" + metadata + references + class_type + ")"
      rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
      data = {api_key: 'h93hq@hwo9%@ah!jsh', rule: rule}
      $.ajax {
        url: "/api/v1/rules"
        method: 'POST'
        data: data
        headers: headers
        success: (response) ->
          $('.alert_rules').removeClass('error')
          $('.alert_rules').addClass('success').show().append('<p>New rule has been created\n</p>')
        error: (response) ->
          $('.alert_rules').removeClass('success')
          $('.alert_rules').addClass('error').show().append('New rule has not been created\n')
        complete: ->
          $(document).ajaxStop ->
            location.reload true
      }

  $('.edit').on "click", '.update-rule-btn', (e) ->
    e.preventDefault()
    form = $(this).parents('.edit_legacy_form')
    rule_content = form.find('textarea[name="rule[rule_content]"]').val()
    id = form.find('input[name="rule_id"]').val()
    rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val()}
    data = {id: id, rule: rule}
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
        $(document).ajaxStop ->
          location.reload true
    }