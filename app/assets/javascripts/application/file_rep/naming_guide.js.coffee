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


#### FUNCTIONS FOR THE NAMING GUIDE PAGE ####
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


  # Sorting elements function
  window.getSorted = (selector, attrName) ->
    $ $(selector).toArray().sort((a, b) ->
      aVal = parseInt(a.getAttribute(attrName))
      bVal = parseInt(b.getAttribute(attrName))
      aVal - bVal
    )

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

    # Revert original sort NUMBERS, remove temp data attribute
    $(rows).each ->
      org_seq = $(this).attr('data-org-seq')
      $(this).attr('data-sort-sequence', org_seq)
      $(this).removeAttr('data-org-seq')
    # Revert to original sort ORDER
    window.getSorted('.amp-naming-row', 'data-sort-sequence')





  # TODO Figure out how to revert to original sort



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
    # compare changes
    # check for new rows
    # save to db


