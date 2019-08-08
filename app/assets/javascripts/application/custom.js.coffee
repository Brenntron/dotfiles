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
