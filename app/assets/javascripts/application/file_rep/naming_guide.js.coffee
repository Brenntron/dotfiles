# dbinebri: for file rep - naming guide modal active state
$ ->
  # clicking the naming guide nav button, remove background darkness, light nav state
  $('#nav-banner a#naming-guide').click ->
    $('#modal-naming-guide').modal({
      backdrop: true,
      keyboard: false
    })
    $('a#naming-guide').addClass('light')
    $('.modal-backdrop').css('opacity','0')

  # when closing modal restore nav state, normal opacity levels
  $('#modal-naming-guide, #modal-naming-guide button.close').click ->
    $('.nav-naming-guide a#naming-guide').removeClass('light')
    # ensure other file rep modals get the normal backdrop opacity
    $(this).fadeOut().delay(500).queue ->
      $('.modal-backdrop').css('opacity','0.5')
