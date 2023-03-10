$ ->
  # dbinebri: file rep, naming guide dialog. includes fix for height resizing bug.

  window.format_amp_contacts = (contacts) ->
    contacts.each ->
      if $(this).hasClass('table-content') || contact != ''
        contact = this.textContent
      else
        contact = this.attr('data')
      email = contact.match(/\S+[a-z0-9]@[a-z0-9\.]+/img );
      if email != null
        email = email[0].replace(/<|\(/g, '')
        contact = contact.replace("#{email}", "")
        new_email = "<span class='amp-email'>#{email}</span>"
        contact = contact.replace('()', '').replace('<>', '')
        contact += new_email

      if  contact.match("https(.*)")!= null
        url =  contact.match("https(.*)")[0]
        contact = contact.replace("#{url}", "")
        url = "<a href='#{url}' class='amp-url' target='_blank'>#{url}</a>"
        contact += url
      if $(this).hasClass('contact-col')
        $(this).html(contact)
      else if $(this).find('.formatted-contact').length > 0
        $(this).find('.formatted-contact').append(contact)
      else
        $(this).html(contact)

  if location.pathname == "/escalations/file_rep/naming_guide"
    contacts = $('.amp-contact')
    format_amp_contacts(contacts)

  $('#naming-guide-dialog').dialog
    autoOpen: false
    width: 930
    minWidth: 930
    height: 500
    minHeight: 300
    position:
      at: "right top"
    open:  () ->
      contacts = $('.contact-col')
      format_amp_contacts(contacts)
    resize: () ->
      $('#naming-guide-dialog').css('height', 'calc(100% - 40px)')



####### FUNCTIONS FOR THE NAMING GUIDE PAGE #######
  # Show editing buttons
  window.edit_amp_naming_conventions = () ->
    inputs_array = []
    inputs_string = ''
    input_new = ''

    $('#amp-edit-button').hide()
    $('.formatted-contact').hide()
    $('.active-editing-buttons').show()

    # Inputs: Save the original state of inputs + textareas in case of Ajax error on Save.
    $('#amp-naming-details-table :input').each ->
      if $(this).attr('class') == 'code-input'
        input_new = 'pattern-' + $(this).val()
      else if $(this).is("textarea")
        input_new = 'textarea-' + $(this).val()
      else
        input_new = $(this).val()
      inputs_array.push(input_new)

    $('#amp-naming-details-table tbody').addClass 'ui-sortable'

    inputs_string = inputs_array.join(',')
    localStorage.setItem('amp_input_values', inputs_string)

  window.cancel_amp_naming_conventions = () ->
    # On cancel, restore the ready-to-delete rows
    $('#amp-naming-details-table').find('.hidden').removeClass('hidden')
    $('#amp-naming-details-table tbody').removeClass 'ui-sortable'
    $('.delete-patterns-area').addClass('hidden')
    $('.delete-patterns-queue').empty()
    $('.formatted-contact').show()

    # Delete any new rows that were not saved
    rows = $('#amp-naming-details-table tbody').find('tr')
    $(rows).each ->
      id = $(this).attr('data-id')
      if id == ''
        $(this).remove()

    # Redefining after the dead rows are gone
    rows = $('#amp-naming-details-table tbody').find('tr')

    # Hide active editing buttons
    $('#amp-edit-button').show()
    $('.active-editing-buttons').hide()

    # Revert any changes
    $(rows).each ->
      # Revert any changed content back to original state
      cells = $(this).find('td')
      $(cells).each ->
        if $($(this).find('input')).length > 0
          content = $($(this).find('.table-content')).text()
          if $(this).hasClass('amp-pattern')
            content = $($(this).find('.table-code')).text()
          $($(this).find('input')).val(content.trim())
        else
          content = $($(this).find('.table-content')).text()
          $($(this).find('textarea')).val(content.trim())

  # Create new row in table
  window.add_amp_naming_conventions = () ->
    number_of_rows = $('#amp-naming-details-table tbody').find('tr').length
    new_sequence_number = number_of_rows + 1
    new_row = """
      <tr class='amp-naming-row' data-id='' data-unsaved-id='#{new_sequence_number}'>'
      <td class='amp-pattern'>
      <span class='table-content'><span class='table-code'></span></span>
      <span class='table-form-content'><input class='code-input' type='text'></input></span>
      </td>
      <td class='amp-example'>
      <span class='table-content'></span>
      <span class='table-form-content'><input class='example-input' type='text'></input></span>
      </td>
      <td class='engine-description'>
      <span class='table-content'></span>
      <span class='table-form-content'><textarea class='engine-description-textarea' type='text'></textarea></span>
      </td>
      <td class='private-engine-description'>
      <span class='table-content'></span>
      <span class='table-form-content'><textarea class='private-engine-description-textarea'></textarea></span>
      </td>
      <td class='amp-contact'>
      <span class='table-content'></span>
      <span class='table-form-content'><textarea class='contact-textarea'></textarea></span>
      <span class='delete-button' onclick="delete_amp_naming_convention('#{new_sequence_number}', '')"></span>
      </td>
      <td class='amp-notes'>
      <span class='table-content'></span>
      <span class='table-form-content'><textarea class='notes-input'></textarea></span>
      </td>
      <td class='amp-public-notes'>
      <span class='table-content'></span>
      <span class='table-form-content'><textarea class='notes-public-textarea'></textarea></span>
      </td>
      </tr>
      """

    $('#amp-naming-details-table').append(new_row)


  # Save all changes and additions
  window.save_amp_naming_conventions = () ->
    # Update static content to match updated content
    # and prep for saving
    rows = $('#amp-naming-details-table tbody').find('tr')
    rows_changed = []
    newRowsWithErrors = []
    sendToTI = true

    $(rows).each ->
      row = this
      nochange = true
      # Copy any new or changed content to the static rows
      cells = $(row).find('td')
      $(cells).each ->
        if $($(this).find('input')).length > 0
          input = $($(this).find('input')).prop('value')
          input = $.trim(input)
          $(this).attr('defaultValue', input)
          if $(this).hasClass('amp-pattern')
            text = $(this).find('.table-code')
            content = $(text).text()
            content = $.trim(content)
          else
            text = $(this).find('.table-content')
            content = $(text).text()
            content = $.trim(content)
          if content != input
            nochange = false
          content = input
          $(text).text(content)
        else
          textarea = $($(this).find('textarea')).prop('value')
          textarea = $.trim(textarea)
          text = $(this).find('.table-content')
          content = $(text).text()
          content = $.trim(content)
          if $(this).hasClass('amp-contact')
            textarea = textarea.replace(/(\r\n|\n|\r|<|>|\(|\))/gm, "")
            content = content.replace(/(\r\n|\n|\r|<|>|\(|\))/gm, "")
          else
            textarea = textarea.replace(/(\r\n|\n|\r)/gm, "")
            content = content.replace(/(\r\n|\n|\r)/gm, "")
          if content != textarea
            nochange = false
          content = textarea
          $(text).text(content)

      # Remove temp attribute
      $(row).removeAttr('data-org-seq')

      # Put changed and new rows in an array
      if nochange == false
        rows_changed.push(this)

    # Prep new arrays for sending to db
    # This may need to change, not sure how we'll want this formatted
    rows_to_update = []
    rows_to_add = []
    $(rows_changed).each ->
      id = $(this).attr('data-id')
      pattern = $($(this).find('.amp-pattern')[0]).find('.table-code').text()
      example = $($(this).find('.amp-example')[0]).find('.table-content').text()
      private_engine_desc = $($(this).find('.private-engine-description')[0]).find('.table-content').text()
      engine_desc = $($(this).find('.engine-description')[0]).find('.table-content').text()
      contact = $($(this).find('.amp-contact')[0]).find('.table-content').text()
      notes = $($(this).find('.amp-notes')[0]).find('.table-content').text()
      public_notes  = $($(this).find('.amp-public-notes')[0]).find('.table-content').text()

      # Check to make sure no new rows are fully blank
      if pattern == '' && example == '' && private_engine_desc == '' && engine_desc == '' && notes == '' && public_notes == '' && contact == ''
        $(this).remove()

      else if pattern == '' || example == '' || private_engine_desc == '' || engine_desc == ''
        newRowsWithErrors.push($(this))
      else
        unless id == ''
          rows_to_update.push(
            'id': id,
            'pattern': pattern,
            'example': example,
            'private_engine_description': private_engine_desc,
            'engine_description': engine_desc,
            'notes': notes,
            'public_notes': public_notes,
            'contact': contact
          )
        # New rows won't have an id yet
        else
          rows_to_add.push(
            'pattern': pattern,
            'example': example,
            'private_engine_description': private_engine_desc,
            'engine_description': engine_desc,
            'notes': notes,
            'public_notes': public_notes,
            'contact': contact
          )

    if newRowsWithErrors.length > 0
      showNewRowErrorMessage()
      return

    # Hide active editing buttons
    $('#amp-edit-button').show()
    $('.active-editing-buttons').hide()
    $('#amp-naming-details-table tbody').removeClass 'ui-sortable'

    sendToTI = if rows_to_update.length > 0 then false else true

    if rows_to_add.length > 0
      window.create_amp_naming_conventions([rows_to_add], sendToTI)

    sendToTI = if $('.delete-pattern').length > 0 then false else true

    if rows_to_update.length > 0
      window.update_amp_naming_conventions([rows_to_update], sendToTI)

    # Bulk delete on save, are records ready for deletion? Then pass id's array to back-end
    if $('.delete-pattern').length > 0
      delete_id_array = []
      delete_id_list = ''
      delete_pattern_list = ''

      $('.delete-pattern').each (index, element) ->
        if (index == ($('.delete-pattern').length - 1))
          delete_pattern_list += '"' + $(this).text() + '"'
          delete_id_list += $(this).attr('data-delete-id')
        else
          delete_pattern_list += '"' + $(this).text() + '", '
          delete_id_list += $(this).attr('data-delete-id') + ','

      $('.delete-patterns-area').addClass('hidden').empty()
      delete_id_array = delete_id_list.split(',')

      # Delete ajax call
      std_msg_ajax(
        method: 'DELETE'
        url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention"
        # delete should always update ti
        data: { 'ids': delete_id_array, 'send_to_ti': true }
        success: (response) ->
          std_msg_success('Secure Endpoint Naming Convention(s) Have Been Deleted.', [delete_pattern_list], reload: false)
        error: (response) ->
          # On ajax error, restore the ready-to-delete rows
          $('#amp-naming-details-table').find('.hidden').removeClass('hidden')
          $('.delete-patterns-area').addClass('hidden')
          $('.delete-patterns-queue').empty()
          std_msg_error('Error Deleting ' + delete_pattern_list, [response.responseText], reload: true)
        async: false
      )


  # Delete one or more naming conventions
  window.delete_amp_naming_convention = (id, pattern) ->
    delete_id_array = []
    delete_id_list = ''

    # Hide the row that was deleted
    delete_row = 'tr[data-id=' + id + ']'
    $(delete_row).addClass('hidden')

    # If unsaved row, store this id for logic below
    unsaved_id = $('tr[data-unsaved-id=' + id + ']').attr('data-unsaved-id')

    # If this is a new and unsaved row, just remove it from page
    if unsaved_id != undefined
      delete_row = 'tr[data-unsaved-id=' + id + ']'
      $(delete_row).addClass('hidden')
    else
      $('.delete-patterns-area').removeClass('hidden')

      delete_pattern_html = '<span class="delete-pattern" data-delete-id="' + id + '">' + pattern + '</span>'
      $('.delete-patterns-queue').append(delete_pattern_html)


  window.create_amp_naming_conventions = ([data], sendToTI) ->
    # Pulling out just patterns for response message
    response_data = ""
    if data.length > 1
      $(data).each ->
        response_data += "'" + this.pattern + "', "
    else
      response_data = data[0].pattern
    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention"
      data: { patterns: data, send_to_ti: sendToTI }
      success: (response) ->
        std_msg_success('The Following Secure Endpoint Naming Conventions Have Been Created:', [response_data], reload: false)
        if $('[data-unsaved-id]').length > 0
          $('[data-unsaved-id]').each ->
            newRecords = response['json']['new_records']
            patternValue = $(@).find('.amp-pattern').attr('defaultValue')
            matchingRecord = (record for record in newRecords when record.pattern is patternValue)[0]
            if matchingRecord
              $(@).attr('data-id', matchingRecord.id)
              $(@).removeAttr('data-unsaved-id')
              $(@).find('.delete-button').attr('onclick',"delete_amp_naming_convention('#{matchingRecord.id}', '#{matchingRecord.pattern}')")
      error: (response) ->
        $('tr[data-unsaved-id]').hide()
        std_msg_error('Error Creating Secure Endpoint Naming Conventions', [response.responseText], reload: false)
      async: false
    )


  window.update_amp_naming_conventions = ([data], sendToTI) ->
    # Pulling out just patterns for response message
    response_data = ""
    if data.length > 1
      $(data).each ->
        response_data += "'#{this.pattern}', "
    else
      response_data = data[0].pattern

    std_msg_ajax(
      method: 'PATCH'
      url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention"
      data: { patterns: data, send_to_ti: sendToTI }
      success: (response) ->
        std_msg_success('Secure Endpoint Naming Conventions Have Been Updated', ["Relevant changes have also been sent to TI."], reload: true)
        contacts = $('.amp-contact .table-content')
        format_amp_contacts(contacts)
      error: (response) ->
        window.restore_input_values()
        std_msg_error('Error Updating Secure Endpoint Naming Conventions', [response.responseText], reload: true)
      async: false
    )


  window.restore_input_values = () ->
    count = 0
    form_count = 0

    inputs_string = ''
    inputs_array = []
    text_array = []
    text_form_array = []

    inputs_string = localStorage.getItem('amp_input_values')
    inputs_array = inputs_string.split(',')

    text_array = $('#amp-naming-details-table td span.table-content')
    text_form_array = $('#amp-naming-details-table td span.table-form-content')

    text_array.each ->
      if inputs_array[count].indexOf('pattern-') == 0
        $(this).html('<span class="table-content"><span class="table-code">' + inputs_array[count].replace('pattern-','') + '</span></span>')
      else if inputs_array[count].indexOf('textarea-') == 0
        $(this).html('<span class="table-content">' + inputs_array[count].replace('textarea-','') + '</span>')
      else
        $(this).html('<span class="table-content">' + inputs_array[count] + '</span>')
      count++

    text_form_array.each ->
      if inputs_array[form_count].indexOf('pattern-') == 0
        $(this).html('<input type="text" class="code-input" value="' + inputs_array[form_count].replace('pattern-','') + '">')
      else if inputs_array[form_count].indexOf('textarea-') == 0
        $(this).html('<textarea class="notes-input">' + inputs_array[form_count].replace('textarea-','') + '</textarea>')
      else
        $(this).html('<input type="text" value="' + inputs_array[form_count] + '">')
      form_count++



  $('#nav-banner #naming-guide').click ->
    $('#naming-guide-dialog').dialog('open')

  showNewRowErrorMessage = () ->
    std_msg_error('Error Adding Secure Endpoint Naming Convention', ['Pattern, Example, Engine Description, and Private Engine Description are required fields.'], reload: false)
