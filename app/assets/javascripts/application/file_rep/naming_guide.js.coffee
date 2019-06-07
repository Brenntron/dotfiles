$ ->
  # dbinebri: file rep, naming guide dialog. includes fix for height resizing bug.
  $('#naming-guide-dialog').dialog
    autoOpen: false
    width: 800
    minWidth: 700
    height: 500
    minHeight: 300
    position:
      at: "right top"
    resize: () ->
      $('#naming-guide-dialog').css('height', 'calc(100% - 40px)')

  $('#nav-banner #naming-guide').click ->
    $('#naming-guide-dialog').dialog('open')
