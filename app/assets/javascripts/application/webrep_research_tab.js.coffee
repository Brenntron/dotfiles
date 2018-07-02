$ ->
  $('#edit-dispute-entry-button').click ->

    if ($('.dispute_check_box:checked').length > 0)
      $('.edit-entries-buttons').toggleClass('hidden')
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
          entry_id = $(this).attr('data-entry-id')

          entry_content_wrapper = $(this).parent().parent()[0]
          editable_data = $(entry_content_wrapper).find('.entry-data')
          $(editable_data).each ->
            $(this).hide()
            data_input = $(this).next('.table-entry-input').show()

          first_item = $(editable_data)[0]
          $(first_item).next('.table-entry-input')[0].focus()
    else
      alert ('Select at least one entry to edit.')

#  $('.cancel-changes').click ->


#        After this is edited the user has to hit save, add a placeholder button for now above the table.
#        When they hit save it should send the update to the ticket, populate everywhere / reload the page, and set the entry span to match
#        the content of the input



#  Expand / Collapse the expandable row
  $('.expand-row-button-inline').click ->
    expand_button = $(this)
    entry_id = $(this).attr('data-entry-id')
    entry_row = $(this).parents('.research-table-row')[0]
    nested_row = $(entry_row).find('.nested-data-row')[0]
    $(nested_row).toggle()
    $(expand_button).toggleClass('shown')


# Show / hide the different research tables in the expanded row
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


