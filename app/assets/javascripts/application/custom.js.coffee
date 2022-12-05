$ ->
  $('.sidebar-toggle').click ->
    $('#main-content').toggleClass("shifted--right")
    $('.login-area').toggleClass("shifted--left")
    $('.sidebar').toggleClass("nav--active")

  # ensure side nav is always correct viewport height in all browsers
  $('#sidenav-icons-div').css("height", $(document).height())

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

  download_csv = (csv, filename) ->
    # CSV FILE
    csvFile = new Blob([csv], type: 'text/csv')
    # Download link
    downloadLink = document.createElement('a')
    # File name
    downloadLink.download = filename
    # We have to create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile)
    # Make sure that the link is not displayed
    downloadLink.style.display = 'none'
    # Add the link to your DOM
    document.body.appendChild downloadLink
    # Lanzamos
    downloadLink.click()
    return

  export_table_to_csv = (html, filename) ->
    csv = []
    rows = document.querySelectorAll('table tr')
    i = 0
    while i < rows.length
      row = []
      cols = rows[i].querySelectorAll('td, th')
      j = 0
      while j < cols.length
        row.push cols[j].innerText
        j++
      csv.push row.join(',')
      i++
    # Download CSV
    download_csv csv.join('\n'), filename
    return

#    CSV Export Feature How-To:
#  Add a button to a page and give it the ID "export_csv". Clicking this button
#  will select everything in the first <table> of class "csv_exportable", dump
#  it to CSV, and download it.
  $('#export_csv').click ->
    html = $('.csv_exportable')[0].outerHTML
    export_table_to_csv html, 'table.csv'
    return

window.show_message = (status, content, timer, selector) ->
  $('.modal').modal('hide')  # hide residuals
  $('.alert-dismissable').remove()
  $('.inline-loader-wrapper:not(.upper-left)').addClass('hidden')  # hide residual gears

  switch status
    when "success" then div_start = "<div class='alert alert-success alert-dismissable'>"
    when "error" then div_start = "<div class='alert alert-danger alert-dismissable'>"
    when "info" then div_start = "<div class='alert alert-info alert-dismissable'>"

  div_end = "<a href='#' class='close' data-dismiss='alert' aria-label='close'>&times;</a></div>"

  # selector of 'undefined' is default, other placements can be added
  if selector != undefined
    div_start = div_start.replace('alert-dismissable', 'alert-dismissable alert-streamlined')

    # build the full alert div html
    $(selector).before("#{div_start} #{content} #{div_end}")
  else
    # default alert placement here is near top-center
    $('.tab-top:visible').append("#{div_start} #{content} #{div_end}")

  # if timer is defined, auto-dismiss the alert. if timer not defined (or false), leave alerts alone
  if timer != undefined && timer != false
    timer = parseInt(timer) * 1000  # 5 sec == 5000 ms
    setTimeout ->
      $('.alert-dismissable').fadeOut()
    , timer

  # after activated, toolbar buttons should hide residual alerts
  $('.toolbar-button').mouseup ->
    $('.alert-dismissable').remove()  # use mouseup() above instead of click()

$ ->
  # dropdowns should be able to be closed on clicking outside of the dropdown
  # but should NOT be closed if a user is dismissing a success or error modal
  # should work across ACE
  $('.dropdown').on 'hide.bs.dropdown', (e) ->
    dropdown = this
    if $('body').hasClass('modal-open')
      e.preventDefault()
      # clear loader if exists
      $(this).find('.lookup-drop-loader').addClass('hidden')
