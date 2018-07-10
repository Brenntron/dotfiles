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
#        When they hit save it should send the update to the ticket,
  #      populate everywhere / reload the page,
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


#  Populating the toolbar Adjust RepTool Button
  $('#reptool_entries_button').click ->
    if ($('.dispute_check_box:checked').length > 0)
      $('.dispute_check_box').each ->
        if $(this).prop('checked')
#          debugger
          entry_row = $(this).parents('.research-table-row')[0]
          entry_content = $(entry_row).find('.entry-data-content').text()
          entry_rep_class = $(entry_row).find('.entry-reptool-class').text()
          entry_rep_exp = $(entry_row).find('.entry-reptool-expiration').text()

          show_content = $('#reptool_adjust_entries').find('.entry-dispute-name')
          $(show_content[0]).text(entry_content)

          show_rep_class = $('#reptool_adjust_entries').find('.entry-reptool-class')
          show_rep_exp = $('#reptool_adjust_entries').find('.entry-reptool-expiration')
          if entry_rep_class == "Not on RepTool"
            $(show_rep_class).addClass('missing-data')
            $(show_rep_exp).addClass('missing-data')
            $(show_rep_exp[0]).text('N/A')
          else
            $(show_rep_exp[0]).text(entry_rep_exp)
          $(show_rep_class[0]).text(entry_rep_class)

    else
      alert ('No rows selected')


#  Populating the toolbar Adjust WL/BL Button
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

          entry_list_val = ''
          preview_button = $('#wlbl_adjust_entries').find('.wlbl-preview-button')
          comment_wrapper = $('#wlbl_adjust_entries').find('.comment-wrapper')
          submit_button = $('#wlbl_adjust_entries').find('.dropdown-submit-button')

          $(wlbl_options).each ->
            option_value = $(this).val()
            wlbl = $(entry_row).find('.entry-data-wlbl').text()
            if $.trim(option_value) == $.trim(wlbl)
              entry_list_val = $(select_wlbl).val(option_value)
            else
              entry_list_val = $(select_wlbl).val()

          $(select_wlbl).change ->
            new_val = $(select_wlbl).val()
            if new_val != entry_list_val
              $(preview_button).removeAttr("disabled")
            else if new_val ==  entry_list_val
              unless $(preview_button).attr("disabled", true)
                $(preview_button).attr("disabled", true)

          $(preview_button).click ->
            if $(preview_button).attr("disabled", false)
              $(comment_wrapper).show()
              $(submit_button).removeAttr("disabled")

    else
      alert ('No rows selected')


#  Inline Adjust WL/BL Button
  $('.dispute-inline-buttons.adjust-wlbl-button').click ->

    entry_row = $(this).parents('.research-table-row')[0]
    wlbl = $(entry_row).find('.entry-data-wlbl').text()
    dropdown = $(this).next('.dropdown-menu')
    select_wlbl = $(dropdown).find('.adjust-wlbl-input')
    wlbl_options = $(select_wlbl).find('option')

    preview_button = $(dropdown).find('.wlbl-preview-button')
    comment_wrapper = $(dropdown).find('.comment-wrapper')
    submit_button = $(dropdown).find('.dropdown-submit-button')

    $(select_wlbl).change ->
      new_val = $(select_wlbl[1]).val()
      wlbl = $.trim(wlbl)
      if wlbl == "Not currently on a list"
        wlbl = ""

      if new_val != wlbl
        $(preview_button).removeAttr("disabled")
      else if new_val ==  wlbl
        $(preview_button).attr("disabled", true)
        $(comment_wrapper).hide()
        $(submit_button).attr("disabled", true)

    $(preview_button).click ->
      if $(preview_button).attr("disabled", false)
        $(comment_wrapper).show()
        $(submit_button).removeAttr("disabled")


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
