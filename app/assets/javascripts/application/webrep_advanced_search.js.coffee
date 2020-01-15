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
      if field_name == 'category-input-selectized'
        field_name = 'category-input'
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




  $('.search-criteria-label').click ->
    window.toggle_search_criteria(this)

  $('.remove-input').click ->
    window.toggle_search_criteria(this)


# Doing this a little bit differently to help with storing user preferences
window.toggle_search_criteria = (element) ->
  search_wrapper = $(element).parents('#advanced-search-wrapper')[0]
  debugger
  if $(element).hasClass('search-criteria-label')
    # show criteria
    criteria = $($(element).find('.search-checkbox')[0]).attr('for')
    criteria_wrapper = $(element).parents('li')[0]
    search_input = $(search_wrapper).find('#' + criteria)[0]
    input_wrapper = $(search_input).parents('.search-item')[0]

    $(criteria_wrapper).addClass('hidden')
    $(input_wrapper).removeClass('hidden')

  else if $(element).hasClass('remove-input')
    # hide criteria
    input_wrapper = $(element).parents('.search-item')[0]
    search_input = $(input_wrapper).find('.form-control')[0]
    criteria = $(search_input).attr('id')
    criteria_toggle = $(search_wrapper).find('input[for="' + criteria + '"]')
    criteria_wrapper = $(criteria_toggle).parents('li')[0]

    $(input_wrapper).addClass('hidden')
    $(criteria_wrapper).removeClass('hidden')

  # grab visible criteria
  search_criteria = $(search_wrapper).find('.search-item')
  search_pref = []
  $(search_criteria).each ->
    console.log 'shit'
    unless $(this).hasClass('hidden')
      search_item = $($(this).find('.form-control')).attr('id')
      search_pref.push(search_item)

  data = search_pref.join()
  console.log data
  # save to db
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/user_preferences/update"
    method: 'POST'
    data: {data, name: 'WebCatAdvancedSearchFieldsDisplayed'}
    dataType: 'json'
    success: (response) ->
  )
