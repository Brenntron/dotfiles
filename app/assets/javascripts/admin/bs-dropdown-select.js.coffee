# This allows the js within search and create forms to function properly in the navigation dropdowns
# Move this file to application folder after redesign is implemented
$(document).ready ->

  $('.dropdown-menu').on 'click', (event) ->
    event.stopPropagation()
    return

  $('body').on 'click', (event) ->
    target = $(event.target)
    if target.parents('.bootstrap-select').length
      event.stopPropagation()
      $('.bootstrap-select.open').removeClass 'open'
    return
  return
