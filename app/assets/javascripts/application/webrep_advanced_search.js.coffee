$(document).ready ->

  $('#advanced-search-dropdown').on 'click', (event) ->
    event.stopPropagation()
    return

  $('#search-webrep-cases-form').on 'click', (event) ->
    event.stopPropagation()
    return

  $('.add-search-items-button').click ->
    event.stopPropagation()
    $('#search-criteria-options').show()
    false

