$ ->
  # dbinebri: for file rep - naming guide dialog
  $('#naming-guide-dialog').dialog
    autoOpen: false
    resizable: true
    width: 800
    minWidth: 700
    maxWidth: 1200
    position:
      my: "left bottom"
      at: "right top"
      of: window

  $('#nav-banner a#naming-guide').click ->
    $('#naming-guide-dialog').dialog('open')
