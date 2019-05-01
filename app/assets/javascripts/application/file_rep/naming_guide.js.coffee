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
    $('#amp-save-button').show()
    $('#amp-cancel-button').show()

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
    $('#amp-save-button').hide()
    $('#amp-cancel-button').hide()
    $('#amp-naming-details-table tbody').sortable 'destroy'
