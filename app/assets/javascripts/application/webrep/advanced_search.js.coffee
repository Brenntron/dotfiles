$(document).ready ->
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
