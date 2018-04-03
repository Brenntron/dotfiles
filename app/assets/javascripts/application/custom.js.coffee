$ ->
  $('.sidebar-toggle').click ->
    $('#main-content').toggleClass("shifted--right")
    $('.login-area').toggleClass("shifted--left")
    $('.sidebar').toggleClass("nav--active")

  #remove whitespace from search form
  $('#search_form').submit ->
    bug_id = $('#bug_id').val().trim()
    $("#bug_id").val(bug_id)

  # go back to the last tab after reload
  $('a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
    localStorage.setItem 'lastTab', $(this).attr('class')
    return

  $(document).on 'ready page:load', (e) ->
    lastTab = localStorage.getItem('lastTab')
    if lastTab
      $('#bug_tab a[class= "' + lastTab + '"]').tab('show');
    return