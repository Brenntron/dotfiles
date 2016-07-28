$ ->

  $(document).on 'click', '#attachments-current', ->
    $('#current-attachments').show()
    $('#obsolete-attachments').hide()

  $(document).on 'click', '#attachments-obsolete', ->
    $('#current-attachments').hide()
    $('#obsolete-attachments').show()

  $(document).on 'click', '#showAddAttachsToggle, #hideAddAttachsToggle', (e) ->
    e.preventDefault()
    $('#hideAddAttachsToggle, #showAddAttachsToggle, .attach_button').toggle()

  $(document).on 'click','.selectallcheckbox', ->
    $(".attach_check_box").prop("checked", $(".selectallcheckbox").prop("checked"))



  $(document).on 'submit', '#attachment_form', (e) ->
    e.preventDefault()
    data = new FormData()
    data.append( 'bug_id', $('input[name=bug_id]').val())
    data.append( 'attachment[summary]', $('input[name=summary]').val())
    data.append( 'attachment[file_data]', $('input[name="file_name"]')[0].files[0])
    $.ajax {
      url: "/attachments"
      data: data
      processData: false
      contentType: false
      type: 'POST'
      dataType:'json'
      success: (response) ->
        attachment = response.attachment
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
      error: (response) ->
        $('.alert_attachments').addClass('error').show().html(response.responseText)
      complete: ->
        setTimeout (->
            $('.alert_attachments').hide 'blind', {}, 500
            return
          ), 5000
    }

