# dbinebri: for file rep - naming guide dialog
$ ->
  $('#dialog-naming-guide').dialog
    autoOpen: false,
    width: 800,
    height: 500,
    position:
      my: "left bottom"

  $('#nav-banner a#naming-guide').click ->
    $('#dialog-naming-guide').dialog('open')


#### FUNCTIONS FOR THE NAMING GUIDE PAGE ####

  dragSortHelper = (e, ui) ->
    ui.children().each ->
      $(this).width $(this).width()
      return
    ui

  window.edit_amp_naming_conventions = () ->
    $('#amp-naming-details-table tbody').sortable(
      helper: dragSortHelper
      classes: 'ui-sortable-helper': 'selected'
      placeholder: 'sortable-placeholder'
    ).disableSelection()
