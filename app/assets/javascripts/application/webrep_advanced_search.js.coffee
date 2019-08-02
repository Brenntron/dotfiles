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
        input = $(this).find('.form-control')
        select = $(this).find('select')
        selectize = $(this).find('select.selectize')
        if $(input).attr('id') == cb_for || $(select).attr('id') == cb_for || group_id == cb_for || cb_for.startsWith( $(selectize).attr('id') )
          $(this).removeClass('hidden')

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
      parent = $(this).parent()
      attr_for = $(this).attr('for')
      if field_name.endsWith('-selectized')
        field_name = field_name.replace('-selectized', '')
      if attr_for == field_name || attr_for == field_wrapper
        $( parent ).parent().removeClass('hidden')
    $( field ).addClass('hidden')
    false

  $('#search-webrep-cases-form').on 'click', '.remove-input', ->
    field_name = $(this).parent().find('input').attr('id') || $(this).parent().find('select').attr('id')
    field_wrapper = $(this).parent().attr('id')
    $('.search-checkbox').each ->
      if $(this).attr('for') == field_name
        $($(this).parent()).parent().removeClass('hidden')
      else if $(this).attr('for') == field_wrapper
        $($(this).parent()).parent().removeClass('hidden')
    $($(this).parent()).addClass('hidden')
    return
