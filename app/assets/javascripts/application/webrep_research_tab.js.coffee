$ ->
  $('#edit-dispute-entry-button').click ->

    if ($('.dispute_check_box:checked').length > 0)
      $('.edit-entries-buttons').removeClass('hidden')
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
          entry_row = $(this).parents('.research-table-row')[0]
          $(entry_row).addClass('editing-row')
          editable_data = $(entry_row).find('.entry-data')
          input =  $(entry_row).find('.table-entry-input')
          $(editable_data).each ->
            $(this).hide()
          $(input).each ->
            $(this).show()
          first_item = $(editable_data)[0]
          $(first_item).next('.table-entry-input')[0].focus()
    else
      alert ('Select at least one entry to edit.')


  $('.cancel-changes').click ->
    $('.editing-row').each ->
      editing_inputs = $(this).find('.table-entry-input')
      $(editing_inputs).each ->
        if $(this).attr('type') == 'text'
          entry_wrapper = $(this).prev('.entry-data')
          entry_data = $(entry_wrapper[0]).text()
          new_data = $(this).val()
          unless new_data == entry_data
            new_data = entry_data
          $(this).val(new_data)
          $(entry_wrapper[0]).show()
          $(this).hide()

        else if $(this).is('button')
          entry_parent = $(this).parent('.dropdown')
          entry_wrapper = $(entry_parent).prev('.entry-data')
          entry_data = $(entry_wrapper).text()
          new_data = $(this).text()
          unless new_data == entry_data
            new_data = entry_data
          $(this).text(new_data)
          $(entry_wrapper[0]).show()
          $(this).hide()
      $(this).removeClass('editing-row')
      $('.edit-entries-buttons').addClass('hidden')

#   Need to add save function after editing.

#        After this is edited the user has to hit save, add a placeholder button for now above the table.
#        When they hit save it should send the update to the ticket, populate everywhere / reload the page,
#        and set the entry span to match the content of the input
#


# Inline Edit Button
  $('.inline-edit-entry-button').click ->
    edit_button = $(this)
    entry_row = $(this).parents('.research-table-row')[0]
    $(entry_row).addClass('editing-row')
    editable_data = $(entry_row).find('.entry-data')
    input =  $(entry_row).find('.table-entry-input')
    $(editable_data).each ->
      $(this).hide()
    $(input).each ->
      $(this).show()
    first_item = $(editable_data)[0]
    $(first_item).next('.table-entry-input')[0].focus()
    if $('.edit-entries-buttons').hasClass('hidden')
      $('.edit-entries-buttons').removeClass('hidden')

# Inline Edit Status
  $('.radio-label').click ->
    radio_button = $(this).prev('input[type="radio"')
    $(radio_button[0]).trigger('click')
    dropdown_wrapper = $(this).parents('.inline-dropdown-menu')
    active_status = $(dropdown_wrapper[0]).prev('.inline-select-dropdown')
    if $(radio_button[0]).hasClass('entry-status-radio')
      selected_status = $(radio_button[0]).attr('id')
      $(active_status[0]).text(selected_status)

    li = $(this).parent('.status-radio-wrapper')
    parent = li[0]
    $('.status-radio-wrapper').each ->
      if $(this).hasClass('selected')
        $(this).removeClass('selected')
    $(parent).addClass('selected')

    if radio_button.hasClass('resolution-drodown-menu') or radio_button.hasClass('entry-resolution-radio')
      submenu = $(this).siblings('.dropdown-menu')
      $(submenu[0]).show()
      return false
    else
      $('.ticket-resolution-submenu').hide()


# Expand All Rows
  $('#expand-all-rows').click ->
    $('.research-table-row-wrapper').each ->
      expand_inline_toggle = $(this).find('.expand-row-button-inline')
      unless $(expand_inline_toggle[0]).hasClass('shown')
        $(expand_inline_toggle).addClass('shown')
      expandable_row = $(this).find('.nested-data-row')[0]
      $(expandable_row).show()

# Collapse All Rows
  $('#collapse-all-rows').click ->
    $('.research-table-row-wrapper').each ->
      expand_inline_toggle = $(this).find('.expand-row-button-inline')
      if $(expand_inline_toggle[0]).hasClass('shown')
        $(expand_inline_toggle).removeClass('shown')
      expandable_row = $(this).find('.nested-data-row')[0]
      $(expandable_row).hide()

#  Expand / Collapse the expandable row (inline button)
  $('.expand-row-button-inline').click ->
    expand_button = $(this)
    entry_id = $(this).attr('data-entry-id')
    entry_row = $(this).parents('.research-table-row')[0]
    nested_row = $(entry_row).find('.nested-data-row')[0]
    $(nested_row).toggle()
    $(expand_button).toggleClass('shown')

#  Populating the Adjust WL/BL Button
  $('#wlbl_entries_button').click ->
    if ($('.dispute_check_box:checked').length > 0)
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
          entry_row = $(this).parents('.research-table-row')[0]
          entry_content = $(entry_row).find('.entry-data-content').text()
          wbrs = $(entry_row).find('.entry-data-wbrs-score').text()


          show_content = $('#wlbl_adjust_entries').find('.entry-dispute-name')
          show_wbrs =  $('#wlbl_adjust_entries').find('.current-wbrs-score')
          select_wlbl =  $('#wlbl_adjust_entries').find('#wlbl-list-type-select')

          $(show_content[0]).text(entry_content)
          $(show_wbrs[0]).text(wbrs)
          wlbl_options = $(select_wlbl).find('option')

          $(wlbl_options).each ->
            debugger
            option_value = $(this).val()
            wlbl = $(entry_row).find('.entry-data-wlbl').text()
            console.log(option_value)
            console.log wlbl
            if option_value == wlbl
              console.log 'match'

            else
              console.log 'false'
#            wtf is going on 

    else
      alert ('No rows selected')
#      return false
#        get values
#        populate dropdown form



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

# Scrollable tables in the expanded rows
  $('.table-scrollable').DataTable({
    scrollY: 200,
#    scrollCollapse: true,
    paging: false,
    searching: false,
    ordering: false,
    info: false
  });
