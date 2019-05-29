$ ->
  # dbinebri: for file rep - naming guide dialog
  $('#naming-guide-dialog').dialog
    autoOpen: false
    resizable: true
    width: 700
    minWidth: 700
    height: 500
    minHeight: 500
    maxHeight: 800
    position:
      at: "right top"
    resize: (event, ui) ->
      $('#naming-guide-dialog').css('height', 'calc(100% - 40px)')

  $('#nav-banner #naming-guide').click ->
    $('#naming-guide-dialog').dialog('open')
