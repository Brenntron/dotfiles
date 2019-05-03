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
      if $(this).attr('data-id') == ''
        $(this).remove()

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
      '<td class="amp-engine>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td class="amp-engine-description>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td class="amp-notes>' +
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


  window.save_amp_naming_conventions = () ->
    # Update static content to match updated content
    # and prep for saving
    rows = $('#amp-naming-details-table tbody').find('tr')
    rows_to_update = []
    rows_to_add = []

    $(rows).each ->
      row = this
      nochange = true
      # Copy any new or changed content to the static rows
      cells = $(row).find('td')
      $(cells).each ->
        if $($(this).find('input')).length > 0
          input = $($(this).find('input')).val()
          input = $.trim(input)
          if $(this).hasClass('amp-pattern')
            content = $($(this).find('.table-code')).text()
            content = $.trim(content)
          else
            content = $($(this).find('.table-content')).text()
            content = $.trim(content)
          if content != input
            nochange = false
          content == input
        else
          textarea = $($(this).find('textarea')).val()
          textarea = $.trim(textarea)
          content = $($(this).find('.table-content')).text()
          content = $.trim(content)
          if content != textarea
            nochange = false
          content == textarea

      # Check to see if sequence order has been changed
      org_seq = $(row).attr('data-org-seq')
      if $(this).attr('data-sort-sequence') != org_seq
        nochange = false

      # Remove temp attribute
      $(row).removeAttr('data-org-seq')

      # Put changed rows in one array and new ones in a separate array
      if nochange == false
        row_id = $(row).attr('data-id')
        unless row_id == ''
          rows_to_update.push(this)
        else
          rows_to_add.push(this)

          






