$(document).ready ->

  $('#add-search-items-button').click ->
    $('#search-criteria-options').show()
    false

  $('#cancel-add-criteria').click ->
    $('#search-criteria-options').hide()
    false

  $('#add-search-criteria').click ->
    add_button = $('#add-search-items-button')
    selected_checkboxes = []
    $('.search-checkbox:checked').each ->
      value = $(this).val()
      div = $(document.createElement('div')).addClass('form-group search-item')
      label = $(document.createElement('label')).addClass('content-label-sm')
      input = $(document.createElement('input')).addClass('form-control')
      remove = $(document.createElement('button')).addClass('remove-input')
      $(div).append(label)
      $(label).append(value)
      $(div).append(input)
      $(div).append(remove)

      $($(this).parent()).parent().addClass('hidden')
      $(this).prop 'checked', false

      $(div).insertBefore(add_button)
      return

    $('#search-criteria-options').hide()
    false

  $('.remove-input').click ->
    $($(this).parent()).remove()



  $('#search-webrep-cases-form').on 'click', '.remove-input', ->
    $($(this).parent()).remove()
    return
