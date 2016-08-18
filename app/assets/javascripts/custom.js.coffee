$ ->
  $('.sidebar-toggle').click ->
    $('#main-content').toggleClass("shifted--right")
    $('.login-area').toggleClass("shifted--left")
    $('.sidebar').toggleClass("nav--active")