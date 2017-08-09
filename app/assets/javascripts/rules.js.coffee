window.dismiss_alert_rules = ->
  $('.alert_rules').hide 'blind', {}, 500


window.disparage =(chkbox) ->
  disparage_messages = [
    "You should feel bad about yourself",
    "Really?",
    "Whoa, duuude!",
    "Oh man, did you have to?",
    "Does your mother know you are doing this?",
    "Maybe your low self esteem is just good sense.",
    "Bad dog, no biscuit.",
    "Does Marshall know you are doing this?",
    "Thanks for contributing to the nightmare that is no documentation for the user.",
    "Are you sure you know what you are doing?",
    "OK, but you may have to explain yourself later.",
    "... and there shall be weeping and gnashing of teeth",
    "You're being very undude.",
    "Am I the only one who gives a shit about the rules?!",
    "uncool!",
    "Do you really have such writer’s block that you cannot wait to write a summary?",
    "Would it kill you to write a summary?",
    "OMG, Like, I literally just can't even ...",
    "Mister self important fancy pants, in a such hurry, can’t write a summary.",
    "How dare you?",
    "*ding*  *ding* *ding* Shame, Shame, Shame.",
    "With all we did for you, you couldn't be bothered to write documentation.",
    "I hope you can live with yourself.",
    "Such a thing you are doing, but we still care about you.",
    "What monster would do this?",
    "I won't tell anyone, but *I* know. :(",
    ]

  if (chkbox.checked)
    message_index = Math.floor(Math.random() * disparage_messages.length)
    alert(disparage_messages[message_index])


$ ->
  $('.rule-toolbar').click ->
    tab = $(this).attr('id')
    isSelected = false
    selected = []
    selected_sids = []
    allboxes = []
    $('input:checkbox.rule_check_box').each ->
      allboxes.push($(this).val())
      if @checked
        isSelected = true
        selected.push($(this).val())
        selected_sids.push($(this).attr('data-sid'))
    allboxes = $.unique(allboxes)
    sid_text = if selected_sids.length > 1 then 'sids ' else 'sid '
    if isSelected or tab in ['overview','create','export']
      switch(tab)
        when 'export'
          headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
          bug_id = $('input[name="bug_id"]').val()
          user_id = $('input[name="current_user_id"]').val()
          data = {task: {bugzilla_id: bug_id, rule_array: selected, task_type: "rule", created_by: user_id}}
          arr = {
            bugzilla_id: bug_id,
            rule_array: selected,
          }
          
          window.location.href = "/rules/export?" + $.param( arr )

        when 'test'
          headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
          bug_id = $('input[name="bug_id"]').val()
          user_id = $('input[name="current_user_id"]').val()
          data = {task: {bugzilla_id: bug_id, rule_array: selected, task_type: "rule", created_by: user_id}}
          $.ajax {
            url: "/api/v1/tasks"
            method: 'POST'
            data: data
            headers: headers
            success: (response) ->
              task = response
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
              $('.alert_rules').addClass('success').show().html('Task has been created to test the rule ')
            error: (response) ->
              $('.alert_rules').addClass('error').show().html('Task has not been created ')
            complete: ->
              setTimeout (->
                $('.alert_rules').hide 'blind', {}, 5000
                return
              ), 5000
          }
        when 'revert'
          if window.confirm("Revert " + sid_text + selected_sids.join() + "?")
            headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
            $.ajax {
              url: "/api/v1/rules/revert"
              headers: headers
              data:
                rule_ids: selected
              type: 'PUT'
              dataType: 'json'
              success: (response) ->
                $('.alert_rules').addClass('success').show().html('Rules has been reverted')
              error: (response) ->
                $('.alert_rules').addClass('error').show().html('Rules have not been reverted')
              complete: ->
                setTimeout (->
                  $('.alert_rules').hide 'blind', {}, 500
                  return
                ), 5000
                $(document).ajaxStop ->
                  location.reload true
            }
        when 'remove'
          if window.confirm("Remove " + sid_text + selected_sids.join() + "?")
            headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
            bug_id = $('input[name="bug_id"]').val()
            $.ajax {
              url: "/api/v1/bugs/#{bug_id}/rules/unlink"
              headers: headers
              data:
                rule_ids: selected
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
        when 'commit'
          if window.confirm("Are you sure?")
            headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
            $.ajax {
              url: "/api/v1/rules/commit"
              headers: headers
              data:
                rule_ids: selected
                username: $('#username').text()
                bug_id: $('.bugzilla_id').text()
                nodoc_override: $('#missing-doc-override')[0].checked
              type: 'PUT'
              dataType: 'json'
              success: (response) ->
                $('.alert_rules').addClass('success').show().html('Rules has been committed')
                setTimeout (->
                  $('.alert_rules').hide 'blind', {}, 500
                  return
                ), 5000
                $(document).ajaxStop ->
                  location.reload true
              error: (response) ->
                if response.responseJSON == undefined
                  response_lines = response.responseText.split("\n")
                  if 2 < response_lines.length
                    alert(response_lines[0] + "\n" + response_lines[1])
                  else
                    alert(response.responseText)
                else
                  alert(response.responseJSON["error"])
                $('.alert_rules').addClass('error').show().html('Rules have not been committed.  (Click text to dismiss)')
              complete: ->
            }
        else
          $.each allboxes, (i, v) ->
            $('.rule_'+v).removeClass('active').addClass('hidden')
          $.each selected, (i, v) ->
            $('.rule_'+v).removeClass('hidden').addClass('active')
          $('.row.active').addClass('hidden').removeClass 'active'
          $('.' + tab).addClass('active').removeClass 'hidden'
          $('.active').show()
          $('.hidden').hide()
          $('.standard_form').hide()
    else
      alert("please select something")


  $('.show_rule').on 'click', (e) ->
    e.preventDefault()
    id = $(this).parents('tr').attr('id')
    #uncheck all others checkboxes
    $('.rule_check_box').prop('checked', $('.rules_check_box').prop('checked'))
    #check the current rule
    $('#rule_' + id).prop('checked', true)
    $('.view').removeClass('hidden').addClass('active').show()
    $('.overview').removeClass('active').addClass 'hidden'

    $.each $('.rules_table tr'), ->
      `var id`
      id = $(this).attr('id')
      if !isNaN(id)
        $('.rule_' + id).removeClass('active').addClass('hidden').hide()
      return
    $('.rule_' + id).removeClass('hidden').addClass('active').show()
    return

  $('.diff').find('br').remove()

  $(document).on 'click', '#legacy_btn', (e) ->
    $('.standard_form, #legacy_btn').hide()
    $('.legacy_form, #standard_btn' ).show()

  $(document).on 'click', '#standard_btn', (e) ->
    $('.legacy_form, #standard_btn' ).hide()
    $('.standard_form, #legacy_btn').show()

  $(document).on 'click','.rules_check_box', ->
    $(".rule_check_box").prop("checked", $(".rules_check_box").prop("checked"))

  $(document).on 'click','#overview', ->
    $('input:checkbox.rule_check_box').each ->
      $(this).removeClass('hidden')
      $(this).show()

  $('#linkRuleForm').submit (e) ->
    e.preventDefault()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    gid = $('#linkRuleForm input[name="gid"]').val()
    sid = $('#linkRuleForm input[name="sid"]').val()
    bug_id = $('input[name="bug_id"]').val()
    $.ajax {
      url: "/api/v1/bugs/#{bug_id}/rules/#{gid}~#{sid}/link"
      method: 'POST'
      headers: headers
      data: {'api_key': 'h93hq@hwo9%@ah!jsh'}
      success: (response) ->
        window.location.reload()
      error: (response) ->
        $('.alert_rules').removeClass('.success')
        $('.alert_rules').addClass('error').append('Please provide correct rule sid')
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
      if $('.legacy_form')[0].checkValidity()
        form = $(this).parents('.legacy_form');

        legacy_rule_doc = {}
        form.find('textarea[class*=legacy]').each ->
          legacy_rule_doc[$(this)[0].id] = $(this)[0].value

        rule_contents = form.find('textarea[name="rule[rule_content]"]').val()
        contents_arr = rule_contents.split('\n')
        contents_arr.forEach (rule_content) ->
          rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val(), rule_doc: legacy_rule_doc}
          data = { rule: rule}
          $.ajax {
            url: "/api/v1/rules"
            method: 'POST'
            data: data
            headers: headers
            success: (response) ->
              $('.alert_rules').removeClass('error')
              $('.alert_rules').addClass('success').show().append('<p>New rule has been created\n</p>')
              $('html,body').scrollTop(0);
            error: (response) ->
              $('.alert_rules').removeClass('success')
              $('.alert_rules').addClass('error').show().append('New rule has not been created\n')
            complete: ->
              $(document).ajaxStop ->
                location.reload true
          }
      else
        $('.alert_rules').addClass('error').show().append('<p>Please fill in required fields.\n</p>')
        $('.legacy_form').find(":invalid").each (e) ->
          $(this).addClass('onError')
          window.scrollTo(0, 0)
    else if $('.standard_form').is(":visible")
      form = $(this).parents('.standard_form')
      if $('.standard_form')[0].checkValidity()
        form.find('button[name="submitButton"]').click()
        msg = form.find('input[name="rule[message]"]').val()
        category = $('#rule_category_id option:selected').text()
        msg = '(msg:"'+ category +  " " + msg + '";'
#        connection = ""
#        form.find('input[name="rule[connection][]"], select[name="rule[connection][]"]').each ->
#          if $(this).is(":enabled")
#            connection = connection + $(this).val() + " "
#        connection = "connection:" + connection
        flow = ""
        form.find('input[name="rule[flow][]"], select[name="rule[flow][]"]').each ->
          if $(this).is(":enabled")
            flow = flow + $(this).val() + ","
        flow = flow.replace(/,([^,]*)$/,'$1')
        detection = "detection:" + form.find('textarea[name="rule[detection]"]').val()
        metadata = ""
        form.find('input[name="rule[metadata][]"], select[name="rule[metadata][]"]').each ->
          if $(this).is(":enabled")
            if ($(this).is('input') && $(this).is(':checked')) || $(this).is('input[type="text"]')
              metadata = metadata + " " + $(this).val() + ","
            else if $(this).is('select') && $(this).val() != null
              metadata = metadata + " " + $(this).val() + ","
        metadata = metadata.replace(/,([^,]*)$/,'$1')
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

        rule_doc = {}
        $('.rule_doc').find('textarea[class*=standard]').each ->
          rule_doc[$(this)[0].id] = $(this)[0].value

#        rule_content = connection + msg + flow + detection + ";" + metadata + references + class_type + ")"
        rule = {
          connection: {
            action: $('select[name="rule[action]"] option:selected').val(),
            protocol: $('select[name="rule[protocol]"] option:selected').val(),
            src: $('select[name="rule[src]"] option:selected').val(),
            srcport: $('input[name="rule[srcport]"]').val(),
            direction: $('select[name="rule[direction]"] option:selected').val(),
            dst: $('input[name="rule[dst]"]').val(),
            dstport: $('input[name="rule[dstport]"]').val(),
          },
          rule_category_id: $('#rule_category_id option:selected').val(),
          rule_category: $('#rule_category_id option:selected').text(),
          message: form.find('input[name="rule[message]"]').val(),
          flow: flow,
          detection: $('#std-form-detection').val(),
          metadata: metadata,
          class_type: $('#new-rule-classtype-form option:selected').text(),
          references: references,
          bug_id: $('input[name="bug_id"]').val(),
          rule_doc: rule_doc
        }
        $.ajax {
          url: "/api/v1/rules/parts"
          method: 'POST'
          data: {rule: rule}
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
              window.scrollTo(0, 0)
        }
      else
        $('.alert_rules').addClass('error').show().append('<p>Please fill in required fields.\n</p>')
        $('.standard_form').find(":invalid").each (e) ->
          $(this).addClass('onError')

  $('.commit').on "click",(e) ->
    alert("clicked commit")

  $('.edit').on "click", '.update-rule-btn', (e) ->
    e.preventDefault()
    form = $(this).parents('.edit_legacy_form')
    rule_content = form.find('textarea[name="rule[rule_content]"]').val()
    id = form.find('input[name="rule_id"]').val()

    edit_rule_doc = {}
    form.find('textarea[type=text]').each ->
      edit_rule_doc[$(this)[0].id] = $(this)[0].value

    rule = {rule_content: rule_content, bug_id: $('input[name="bug_id"]').val(), rule_doc: edit_rule_doc}
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
          window.scrollTo(0, 0)
    }

  $('.update-rule-parts-btn').on "click", (ev) ->
    ev.preventDefault()
    form = $(this).parents('.rule-parts-form')
    rule_content = form.find('textarea[name="rule[rule_content]"]').val()
    sid = form.find('input[name="rule[sid]"]').val()
    gid = form.find('input[name="rule[gid]"]').val()

    rule_input_data = {}
    form.find('.api-data-input').each ->
      data_index = this.getAttribute("data-index")
      name = this.getAttribute("name")
      value = this.value
      rule_input_data[data_index] = rule_input_data[data_index] || {}
      rule_input_data[data_index][name] = value

    reference_data = []
    for kk of rule_input_data
      reference_data.push rule_input_data[kk]

    data = { rule: JSON.stringify( {references: reference_data} ) }
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax {
      url: "/api/v1/rules/"+gid+"/"+sid+"/rule-parts"
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
          window.scrollTo(0, 0)
    }


  $(document).on "change", '.metadata_form', (e) ->
    id = $(this)[0].id
    $(".bootstrap-switch-id-drop-alert-" + id).toggle();

  $(document).on 'switchChange.bootstrapSwitch', '.bootstrap-switch', (e) ->
    policy = $(this)[0].children[0].children[3].id.substring(11)
    checkbox = $('#' + policy)[0]
    current_val = $(this)[0].children[0].children[3].checked
    if current_val == true
      #update to drop
      new_val = checkbox.value.split(' ').slice(0,2).join(' ') +  ' drop'
    else
      #update to alert
      new_val = checkbox.value.split(' ').slice(0,2).join(' ') +  ' alert'

    checkbox.value = new_val

  $("[name='alert-drop']").bootstrapSwitch();

  $('.multiselect').multiselect(
     buttonClass: 'btn btn-default btn-xs',
     enableFiltering: true,
     nonSelectedText: 'other'
  );

  $(document).on "change", '#new-rule-classtype-form', (e) ->
    classification = $('#new-rule-classtype-form option:selected').text()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax {
      url: '/rules/get_impact/'
      method: 'GET'
      data: {classification: classification}
      headers: headers
      complete: (e) ->
        $('.impact-standard')[0].value = e.responseText

    }

