$ ->

  $(document).on 'click', '#attachments-pcap', ->
    $('#other-attachments').addClass('hidden')
    $('#pcap-attachments').removeClass('hidden').show()
    $('#obsolete-attachments').addClass('hidden')

  $(document).on 'click', '#attachments-other', ->
    $('#pcap-attachments').addClass('hidden')
    $('#other-attachments').removeClass('hidden').show()
    $('#obsolete-attachments').addClass('hidden')

  $(document).on 'click', '#attachments-obsolete', ->
    $('#pcap-attachments').addClass('hidden')
    $('#obsolete-attachments').removeClass('hidden').show()
    $('#other-attachments').addClass('hidden')

  $(document).on 'click', '#showAddAttachsToggle, #hideAddAttachsToggle', (e) ->
    e.preventDefault()
    $('#hideAddAttachsToggle, #showAddAttachsToggle, .attach_button').toggle()

  $(document).on 'click','.selectallcheckbox', ->
    $(".attach_check_box").prop("checked", $(".selectallcheckbox").prop("checked"))

  $(document).on 'click','.attachment_alert', ->
    id = $(this).attr('class')
    id = id.slice(id.indexOf(' ')+1, id.length)
    $('#attachment_'+id).toggle()


  progressHandlingFunction = (e) ->
    if e.lengthComputable
      $('progress').attr
        value: e.loaded
        max: e.total
    return


  $('.add_attachment').on 'click', (e) ->
    success = false
    e.preventDefault()
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    data = new FormData()
    data.append( 'attachment[bugzilla_attachment_id]', $('input[name=bug_id]').val())
    data.append( 'attachment[summary]', $('input[name=summary]').val())
    data.append( 'attachment[file_data]', $('input[id="file_data"]')[0].files[0])
    data = data
    $.ajax(
      url: '/api/v1/attachments'
      method: 'POST'
      headers: headers
      xhr: ->
        # Custom XMLHttpRequest
        myXhr = $.ajaxSettings.xhr()
        if myXhr.upload
        # Check if upload property exists
          myXhr.upload.addEventListener 'progress', progressHandlingFunction, false
        # For handling the progress of the upload
        myXhr
      data: data
      cache: false
      contentType: false
      processData: false
      success:(response) ->
        success = true
        attachment = response.attachments
        $('.success_attachments').html('successfully attached')
        $('#current-attachments').append('<tr>'+
            '<td><input type="checkbox" name='+attachment.id+' class="attachcheckbox"> </td>'+
            '<td class="center narrow-column"><a class="blue" href='+attachment.direct_upload_url+'>'+
            '<i class="glyphicon glyphicon-download"></i></a></td>'+
            '<td><code><a>'+attachment.file_name+'</a></code></td>'+
            '<td class="center narrow-column">'+
            '<h5>'+
            '<a>0</a>'+
            '</h5>'+
            '</td>'+
            '</tr>')
        $('#hideAddAttachsToggle, #showAddAttachsToggle, .attach_button').toggle()
        $('.alert_attachments').addClass('success').show().html(attachment.file_name+' successfully attached')
      error:(response) ->
        $('.alert_attachments').addClass('error').show().html(response.responseText)
    ).done (response) ->
      if success == true
        $(document).ajaxStop ->
          location.reload()

  $(document).on 'click', '#test_attachments',  ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    bug_id = $('input[name="bug_id"]').val()
    user_id = $('input[name="current_user_id"]').val()
    selected = []
    $('input:checkbox.attach_check_box').each ->
      if @checked
        selected.push($(this).val())
    data = {task: {bugzilla_id: bug_id, attachment_array: selected.join(), task_type: "attachment", created_by: user_id}}
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
        $('.alert_attachments').addClass('success').show().html('Task has been created to test the attachment')
      error: (response) ->
        $('.alert_attachments').addClass('error').show().html('Task has not been created')
      complete: ->
        setTimeout (->
          $('.alert_rules').hide 'blind', {}, 5000
          return
        ), 5000
    }


