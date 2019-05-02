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

  maintain_col_width = (e, ui) ->
    ui.children().each ->
      $(this).width $(this).width()
      return
    ui

  window.update_sequence_numbers = () ->
    rows = $('#amp-naming-details-table').find('.ui-sortable-handle')
    r = 0
    $(rows).each ->
      new_sort = r + 1
      $(this).attr('data-sort-sequence', new_sort)
      r++

  window.edit_amp_naming_conventions = () ->
    $('#amp-edit-button').hide()
    $('.active-editing-buttons').show()

    $('#amp-naming-details-table tbody').sortable(
      helper: maintain_col_width
      classes: 'ui-sortable-helper': 'selected'
      placeholder: 'sortable-placeholder'
      stop: (event, ui) ->
        window.update_sequence_numbers()
        return

    ).disableSelection()


  window.cancel_amp_naming_conventions = () ->
    $('#amp-edit-button').show()
    $('.active-editing-buttons').hide()
    $('#amp-naming-details-table tbody').sortable 'destroy'
    # TODO Figure out how to revert to original sort



  window.add_amp_naming_conventions = () ->
    number_of_rows = $('#amp-naming-details-table tbody').find('tr').length
    new_sequence_number = number_of_rows + 1
    new_row =
      '<tr data-sort-sequence="' + new_sequence_number + '" data-id="">' +
      '<td>' +
      '<span class="table-content"><span class="table-code"></span></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><input type="text"></input></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '<td>' +
      '<span class="table-content"></span>' +
      '<span class="table-form-content"><textarea></textarea></span>' +
      '</td>' +
      '</tr>'

    $('#amp-naming-details-table').append(new_row)


  window.save_amp_naming_conventions = () ->
    # compare changes
    # check for new rows
    # save to db


