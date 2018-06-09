$(document).ready ->

  $('#add-search-items-button').click ->
    $('#search-criteria-options').show()
    false

  $('#cancel-add-criteria').click ->
    $('#search-criteria-options').hide()
    false

  $('#add-search-criteria').click ->
    last_current_item = $('.search-item').last()
    selected_checkboxes = []
    $('.search-checkbox:checked').each ->
      value = $(this).val()
      div = $(document.createElement('div')).addClass('form-group search-item')
      label = $(document.createElement('label')).addClass('content-label-sm')
      input = $(document.createElement('input')).addClass('form-control')
      $(div).append(label)
      $(label).append(value)
      $(div).append(input)

      $($(this).parent()).parent().addClass('hidden')
      $(this).prop 'checked', false

      $(last_current_item[0]).after(div)
      return

    $('#search-criteria-options').hide()
    false
