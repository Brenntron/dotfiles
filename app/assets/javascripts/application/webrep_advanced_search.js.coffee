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
      cb_for = $(this).attr('for')
      search_criteria_group = $('#advanced-search-wrapper').find('.form-group')

      $(search_criteria_group).each ->
        group_id = $(this).attr('id')
        input = $(this).find('input')
        select = $(this).find('select')
        if $(input).attr('id') == cb_for || $(select).attr('id') == cb_for || group_id == cb_for
          $(this).removeClass('hidden')
          $('#add-search-criteria')
      $($(this).parent()).parent().addClass('hidden')
      $(this).prop 'checked', false
      return

    $('#search-criteria-options').hide()
    false

  $('.remove-input').click ->
    field = $(this).parent()
    field_name = field.find('input').attr('id') || field.find('select').attr('id')
    field_wrapper = field.attr('id')
    $('.search-checkbox').each ->
      if $(this).attr('for') == field_name
        $(field).parent().removeClass('hidden')
      else if $(this).attr('for') == field_wrapper
        $(field).parent().removeClass('hidden')
    $(field).addClass('hidden')
    false