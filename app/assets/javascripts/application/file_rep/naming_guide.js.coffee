$ ->
  # dbinebri: for file rep - naming guide dialog
  $('#naming-guide-dialog').dialog
    autoOpen: false
    resizable: false
    minWidth: 700
#    maxWidth: 1200

    height: "auto"
#    minHeight: 300
#    maxHeight: 700
#    resize: "auto"
    position:
      my: "left bottom"
#      at: "right top"
#      of: window

  $('#nav-banner a#naming-guide').click ->
    $('#naming-guide-dialog').dialog('open')

