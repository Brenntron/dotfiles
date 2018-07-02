$ ->
  $('#edit-dispute-entry-button').click ->

    $('.dispute_check_box').each ->
      if $(this).prop('checked')
        entry_content_wrapper = $(this).parent().parent()
        entry_id = $(entry_content_wrapper).attr("id")
        entry_span = $(entry_content_wrapper).find($('.table-entry-display'))
        entry_content = $(entry_span[0]).text()

        entry_input = $(entry_content_wrapper).find($('.table-entry-input'))
        entry_input_val = $(entry_input[0]).val()

        $(entry_span[0]).hide()
        $(entry_input[0]).removeClass('hidden').focus()

#        After this is edited the user has to hit save, add a placeholder button for now above the table.
#        When they hit save it should send the update to the ticket, populate everywhere / reload the page, and set the entry span to match
#        the content of the input
      else
        false

#         if no checkboxes are checked alert 'Select at least one dispute entry to edit.'

  $('.expand-row-button-inline').click ->
    expand_button = $(this)
    entry_id = $(this).attr('data-entry-id')
    entry_row = $(this).parents('.research-table-row')[0]
    nested_row = $(entry_row).find('.nested-data-row')[0]

    $(nested_row).toggle()
    $(expand_button).toggleClass('shown')



  $('.research-row-checkbox').click ->
    entry_id = $(this).val()
    entry_row = $(this).parents('.research-table-row')[0]
    if $(this).hasClass('wbrs-checkbox')
      wbrs_table = $(entry_row).find('.wbrs-details-table')[0]
      if $(this).prop('checked')
        $(wbrs_table).show()
      else
        $(wbrs_table).hide()

    if $(this).hasClass('sbrs-checkbox')
      sbrs_table = $(entry_row).find('.sbrs-details-table')[0]
      if $(this).prop('checked')
        $(sbrs_table).show()
      else
        $(sbrs_table).hide()

    if $(this).hasClass('virus-total-checkbox')
      vt_table = $(entry_row).find('.virustotal-details-table')[0]
      if $(this).prop('checked')
        $(vt_table).show()
      else
        $(vt_table).hide()

    if $(this).hasClass('xbrs-checkbox')
      xbrs_table = $(entry_row).find('.xbrs-details-table')[0]
      if $(this).prop('checked')
        $(xbrs_table).show()
      else
        $(xbrs_table).hide()

    if $(this).hasClass('crosslisted-checkbox')
      cl_table = $(entry_row).find('.crosslisted-details-table')[0]
      if $(this).prop('checked')
        $(cl_table).show()
      else
        $(cl_table).hide()


