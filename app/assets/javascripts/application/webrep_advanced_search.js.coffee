$(document).ready ->
  window.set_advanced_search_pref()
  $('#add-search-items-button').click ->
    $('#search-criteria-options').show()
    false

  $('#cancel-add-criteria').click ->
    $('#search-criteria-options').hide()
    false

  $('.search-item').click ->
    $('#search-criteria-options').hide()
    return

  $('#disputes-advanced-search-form .remove-input').click ->

    field = $(this).parent()
    field.find('input').val('')  # on a minus icon click, clear value of field
    field_name = field.find('input').attr('id') || field.find('select').attr('id')
    field_wrapper = field.attr('id')
    $('.search-checkbox').each ->
      parent = $(this).parent()
      attr_for = $(this).attr('for')
      if field_name == 'category-input-selectized'
        field_name = 'category-input'
      if attr_for == field_name || attr_for == field_wrapper
        $( parent ).parent().removeClass('hidden')
    if field.attr('id') == 'submission-type'
      $(field).parent().addClass('hidden')
    else
      $(field).addClass('hidden')
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
  if $(element).hasClass('search-criteria-label')
    # show criteria
    criteria = $($(element).find('.search-checkbox')[0]).attr('for')
    criteria_wrapper = $(element).parents('li')[0]
    search_input = $(search_wrapper).find('#' + criteria)[0]
    input_wrapper = $(search_input).parents('.search-item')[0]

    $(criteria_wrapper).addClass('hidden')
    $(input_wrapper).removeClass('hidden')

    #check if all search criteria has been selected, close form if so
    if $('#search-criteria-options .multicol-2 ul').children(':visible').length == 0
      $('#search-criteria-options').hide()
      $('#add-search-items-button').addClass('hidden')

  else if $(element).hasClass('remove-input')
    # hide criteria
    input_wrapper = $(element).parents('.search-item')[0]
    search_input = $(input_wrapper).find('.form-control')[0]
    criteria = $(search_input).attr('id').replace(/-w-cb/g, '')
    criteria_toggle = $(search_wrapper).find('input[for="' + criteria + '"]')
    criteria_wrapper = $(criteria_toggle).parents('li')[0]
    $('#add-search-items-button').removeClass('hidden')
    $(input_wrapper).addClass('hidden')
    $(criteria_toggle).prop('checked', false)
    $(criteria_wrapper).removeClass('hidden')
  # grab visible criteria
  search_criteria = $(search_wrapper).find('.search-item')
  search_pref = {}
  $(search_criteria).each ->
    search_item = $($(this).find('.form-control')).attr('id')
    if $(this).hasClass('hidden')
      search_pref[search_item] = 'false'
    else
      search_pref[search_item] = 'true'
  data = search_pref
  # save to db
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/user_preferences/update"
    method: 'POST'
    data: {data, name: window.pageFiltersIdentifier() }
    dataType: 'json'
    success: (response) ->
      return false
  )


#  Pull in the saved user preferences of search items
window.set_advanced_search_pref = () ->
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: window.pageFiltersIdentifier()}
    success: (response) ->
      response = JSON.parse(response)
      if response?
        $.each response, (criteria, state) ->
          # submission type has a different DOM stucture, so need to remove the -w-cb
          criteria = criteria.replace(/-w-cb/g, '')
          criteria_id   = '#' + criteria
          search_input  = $($(criteria_id)[0]).parents('.search-item')[0]
          search_toggle = $($('input[for="' + criteria + '"]')[0]).parents('li')[0]
          if state == 'true'
            $(search_input).removeClass('hidden')
            $(search_toggle).addClass('hidden')
          else
            $(search_input).addClass('hidden')
            $(search_toggle).removeClass('hidden')
  )

window.pageFiltersIdentifier = ()->
  if window.location.href.includes('file_rep')
    'FileRepAdvancedSearchFieldsDisplayed'
  else
    'WebRepAdvancedSearchFieldsDisplayed'