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

  $('#disputes-advanced-search-form .remove-input').click ->
    $field = $(this).parent()
    $field_name = $field.find('input').attr('id') || $field.find('select').attr('id')

    $field.find('input').val('')  # on a minus icon click, clear value of field

    $('.search-checkbox').each ->
      $this = $(this)
      $parent = $this.parent()
      attr_for = $this.attr('for')

      if $field_name == 'category-input-selectized'
        $field_name = 'category-input'
      if attr_for == $field_name || attr_for == $field.attr('id')
        $parent.parent().removeClass('hidden')

    if $field.attr('id') == 'submission-type'
      $field.parent().addClass('hidden')
    else
      $field.addClass('hidden')
    false
