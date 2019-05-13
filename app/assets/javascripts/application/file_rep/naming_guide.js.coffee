# dbinebri: for file rep - naming guide dialog
$ ->
  $('#dialog-naming-guide').dialog
    autoOpen: false,
    width: 800,
    height: 500,
    position:
      my: "left bottom"

  $('#nav-banner a#naming-guide').click ->
    $('#dialog-naming-guide').dialog('open')




####### FUNCTIONS FOR THE NAMING GUIDE PAGE #######
  # Keep columns of rows consistent while they are moved
  maintain_col_width = (e, ui) ->
    ui.children().each ->
      $(this).width $(this).width()
      return
    ui

  # Store original sorting numbers in case edits are cancelled
  window.get_original_sort_array = () ->
    # Making temporary attribute for storing original sequence number
    rows = $('#amp-naming-details-table tbody').find('tr')
    $(rows).each ->
      org_seq = $(this).attr('data-sort-sequence')
      $(this).attr('data-org-seq', org_seq)


  # Show editing buttons and make table rows movable (sortable)
  window.edit_amp_naming_conventions = () ->
    $('#amp-edit-button').hide()
    $('.active-editing-buttons').show()
    window.get_original_sort_array()

    $('#amp-naming-details-table tbody').sortable(
      helper: maintain_col_width
      classes: 'ui-sortable-helper': 'selected'
      placeholder: 'sortable-placeholder'
      stop: (event, ui) ->
        window.update_sequence_numbers()
        return
    ).disableSelection()


  # Update sequence numbers if rows are moved
  window.update_sequence_numbers = (row_order) ->
    rows = $('#amp-naming-details-table').find('.ui-sortable-handle')
    r = 0
    $(rows).each ->
      new_sort = r + 1
      $(this).attr('data-sort-sequence', new_sort)
      r++


  window.cancel_amp_naming_conventions = () ->
    # Delete any new rows that were not saved
    rows = $('#amp-naming-details-table tbody').find('tr')
    $(rows).each ->
      id = $(this).attr('data-id')
      if id == ''
        $(this).remove()

    # Redefining after the dead rows are gone
    rows = $('#amp-naming-details-table tbody').find('tr')

    # Turn off sortability
    $('#amp-naming-details-table tbody').sortable('destroy')

    # Hide active editing buttons
    $('#amp-edit-button').show()
    $('.active-editing-buttons').hide()

    # Revert any changes
    $(rows).each ->
      # Revert any changed content back to original state
      cells = $(this).find('td')
      $(cells).each ->
        if $($(this).find('input')).length > 0
          input = $($(this).find('input')).val()
          if $(this).hasClass('amp-pattern')
            content = $($(this).find('.table-code')).text()
          else
            content = $($(this).find('.table-content')).text()
          input == content
        else
          textarea = $($(this).find('textarea')).val()
          content = $($(this).find('.table-content')).text()
          textarea == content
      # Revert original sort NUMBERS, remove temp data attribute
      org_seq = $(this).attr('data-org-seq')
      $(this).attr('data-sort-sequence', org_seq)
      $(this).removeAttr('data-org-seq')

    # Revert to original sort ORDER
    rows =
      $ rows.sort((a, b) ->
        aVal = parseInt(a.getAttribute('data-sort-sequence'))
        bVal = parseInt(b.getAttribute('data-sort-sequence'))
        aVal - bVal
      )

    $('#amp-naming-details-table tbody').empty()
    $(rows).appendTo('#amp-naming-details-table tbody')


  # Create new row in table
  window.add_amp_naming_conventions = () ->
    number_of_rows = $('#amp-naming-details-table tbody').find('tr').length
    new_sequence_number = number_of_rows + 1
    new_row =
      '<tr data-sort-sequence="' + new_sequence_number + '" data-id="">' +
      '<td class="amp-pattern">' +
      '<span class="table-content"><span class="table-code"></span></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td class="amp-example">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td class="amp-engine">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td class="amp-engine-description">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td class="amp-notes">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td class="amp-public-notes">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td class="amp-contact">' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '</tr>'

    $('#amp-naming-details-table').append(new_row)


  # Save all changes and additions
  window.save_amp_naming_conventions = () ->
    # Update static content to match updated content
    # and prep for saving
    rows = $('#amp-naming-details-table tbody').find('tr')
    rows_changed = []

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
          if content != textarea
            nochange = false
          content = textarea
          $(text).text(content)

      # Check to see if sequence order has been changed
      org_seq = $(row).attr('data-org-seq')
      if $(this).attr('data-sort-sequence') != org_seq
        nochange = false

      # Remove temp attribute
      $(row).removeAttr('data-org-seq')

      # Put changed and new rows in an array
      if nochange == false
        rows_changed.push(this)

    # Turn off sortability
    $('#amp-naming-details-table tbody').sortable('destroy')

    # Hide active editing buttons
    $('#amp-edit-button').show()
    $('.active-editing-buttons').hide()

    # Prep new arrays for sending to db
    # This may need to change, not sure how we'll want this formatted
    rows_to_update = []
    rows_to_add = []
    $(rows_changed).each ->
      id = $(this).attr('data-id')
      sequence = $(this).attr('data-sort-sequence')
      pattern = $($(this).find('.amp-pattern')[0]).find('.table-code').text()
      example = $($(this).find('.amp-example')[0]).find('.table-content').text()
      engine = $($(this).find('.amp-engine')[0]).find('.table-content').text()
      engine_desc = $($(this).find('.amp-engine-description')[0]).find('.table-content').text()
      notes = $($(this).find('.amp-notes')[0]).find('.table-content').text()
      public_notes = $($(this).find('.amp-public-notes')[0]).find('.table-content').text()
      contact = $($(this).find('.amp-contact')[0]).find('.table-content').text()

      # Check to make sure no new rows are fully blank
      if pattern == '' && example == '' && engine == '' && engine_desc == '' && notes == '' && public_notes == '' && contact == ''
        $(this).remove()

      else
        unless id == ''
          rows_to_update.push(
            'id': id,
            'pattern': pattern,
            'example': example,
            'engine': engine,
            'engine_description': engine_desc,
            'notes': notes,
            'public_notes': public_notes,
            'contact': contact,
            'table_sequence': sequence
          )
        # New rows won't have an id yet
        else
          rows_to_add.push(
            'pattern': pattern,
            'example': example,
            'engine': engine,
            'engine_description': engine_desc,
            'notes': notes,
            'public_notes': public_notes,
            'contact': contact,
            'table_sequence': sequence
          )

    if rows_to_add.length > 0
      window.create_amp_naming_conventions([rows_to_add])
    if rows_to_update.length > 0
      window.update_amp_naming_conventions([rows_to_update])



  window.delete_amp_naming_convention = (id, pattern) ->
    # DELETE WHEN BACKEND IS READY
    console.log ('Delete this ' + pattern)
    console.log ('id: ' + id)

#    UNCOMMENT OUT WHEN BACKEND IS READY
#    std_msg_ajax(
#      method: 'POST'
#      url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention/delete"
#      data:
#        id: id
#      success: (response) ->
#        std_msg_success('AMP Naming Convention Below Has Been Deleted.', [pattern], reload: false)
#      error: (response) ->
#        std_msg_error('Error Deleting ' + pattern, [response.responseText], reload: false)
#    )



  window.create_amp_naming_conventions = ([data]) ->
    # Pulling out just patterns for response message
    response_data = ""
    if data.length > 1
      data.each ->
        response_data += "'" + this.pattern + "', "
    else
      response_data = data[0].pattern

    # DELETE WHEN BACKEND IS READY
    console.log data
    console.log response_data

    #    UNCOMMENT OUT WHEN BACKEND IS READY
#    std_msg_ajax(
#      method: 'POST'
#      url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention/create"
#      data: data
#      success: (response) ->
#        std_msg_success('The Following AMP Naming Conventions Have Been Created:', [response_data], reload: false)
#      error: (response) ->
#        std_msg_error('Error Creating AMP Naming Conventions', [response.responseText], reload: false)
#    )


  window.update_amp_naming_conventions = ([data]) ->
  # Pulling out just patterns for response message
    response_data = ""
    if data.length > 1
      data.each ->
        response_data += "'" + this.pattern + "', "
    else
      response_data = data[0].pattern

    # DELETE WHEN BACKEND IS READY
    console.log data
    console.log response_data

    #    UNCOMMENT OUT WHEN BACKEND IS READY
#    std_msg_ajax(
#      method: 'PUT'
#      url: "/escalations/api/v1/escalations/file_rep/amp_naming_convention/update"
#      data: data
#      success: (response) ->
#        std_msg_success('The Following AMP Naming Conventions Have Been Updated:', [response_data], reload: false)
#      error: (response) ->
#        std_msg_error('Error Updating AMP Naming Conventions', [response.responseText], reload: false)
#    )

