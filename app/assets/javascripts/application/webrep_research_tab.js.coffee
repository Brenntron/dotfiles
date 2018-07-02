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

