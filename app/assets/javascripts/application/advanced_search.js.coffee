# Doing this a little bit differently to help with storing user preferences
toggle_search_criteria = (element) ->
  $element = $(element)
  $search_wrapper = $element.parents('#advanced-search-wrapper')

  if $(element).hasClass('search-criteria-label')
    # show criteria
    criteria = $($element.find('.search-checkbox')).attr('for')
    $criteria_wrapper = $element.parents('li')
    $search_input = $search_wrapper.find('#' + criteria)
    $input_wrapper = $search_input.parents('.search-item')

    $criteria_wrapper.addClass('hidden')
    $input_wrapper.removeClass('hidden')

    #check if all search criteria has been selected, close form if so
    if $('#search-criteria-options .multicol-2 ul').children(':visible').length == 0
      $('#search-criteria-options').hide()
      $('#add-search-items-button').addClass('hidden')

  else if $element.hasClass('remove-input')
    # hide criteria
    $input_wrapper = $element.parents('.search-item')
    $search_input = $input_wrapper.find('.form-control')
    criteria = $search_input.attr('id').replace(/-w-cb/g, '')
    $criteria_toggle = $search_wrapper.find('input[for="' + criteria + '"]')
    $criteria_wrapper = $criteria_toggle.parents('li')

    $('#add-search-items-button').removeClass('hidden')
    $input_wrapper.addClass('hidden')
    $criteria_toggle.prop('checked', false)
    $criteria_wrapper.removeClass('hidden')

  # grab visible criteria
  $search_criteria = $search_wrapper.find('.search-item')
  search_pref = {}

  name = pageFiltersIdentifier()

  $search_criteria.each ->
    $this = $(this)
    search_item = $($this.find('.form-control')).attr('id')
    if $this.hasClass('hidden')
      search_pref[search_item] = 'false'
    else
      search_pref[search_item] = 'true'
  data = search_pref
  # save to db
  std_msg_ajax(
    url: "/escalations/api/v1/escalations/user_preferences/update"
    method: 'POST'
    data: {data, name: name}
    dataType: 'json'
    success: (response) ->
      return false
  )

#  Pull in the saved user preferences of search items
set_advanced_search_pref = () ->
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/user_preferences/"
    data: {name: pageFiltersIdentifier()}
    success: (response) ->
      response = JSON.parse(response)

      if response?
        $.each response, (criteria, state) ->
          # submission type has a different DOM structure, so need to remove the -w-cb
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

pageFiltersIdentifier = () ->
  href = window.location.href

  if href.includes('file_rep')
    'FileRepAdvancedSearchFieldsDisplayed'
  else if href.includes('webcat')
    'WebCatAdvancedSearchFieldsDisplayed'
  else if href.includes('webrep')
    'WebRepAdvancedSearchFieldsDisplayed'
  else if href.includes('sdr')
    'SDRAdvancedSearchFieldsDisplayed'

$ ->
  set_advanced_search_pref()

  $('#add-search-items-button').click ->
    $('#search-criteria-options').show()

  $('#cancel-add-criteria').click ->
    $('#search-criteria-options').hide()

  $('.search-item').click ->
    $('#search-criteria-options').hide()

  $('.search-criteria-label').click ->
    toggle_search_criteria(this)

  $('.remove-input').click ->
    toggle_search_criteria(this)

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
