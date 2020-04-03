#toolbar shortcuts
window.onkeydown = (e) ->

  #File Reputation - Disputes
  if $('body').hasClass('escalations--file_rep--disputes-controller')
    if (e.altKey && e.which == 84) #alt + t
      $('.take-ticket-button-full').click() #take ticket
    else if (e.altKey && e.ctrlKey && e.shiftKey && e.which == 80) #alt + ctrl + shift + p
      export_file_rep_all() #export all files to .csv
    else if (e.altKey && e.ctrlKey && e.which == 80) #alt + ctrl + p
      export_file_rep_selected() #export selected files to .csv

  #Web Reputation - Disputes
  else if $('body').hasClass('escalations--webrep--disputes-controller')
    if (e.altKey && e.which == 71) #alt + g
      $('#expand-all-index-rows').click() #expand all tickets
    else if (e.altKey && e.which == 72) #alt + h
      $('#collapse-all-index-rows').click() #collapse all tickets
    else if (e.altKey && e.which == 84) #alt + t
      take_disputes() #take ticket
    else if (e.altKey && e.ctrlKey && e.shiftKey && e.which == 80) #alt + ctrl + shift + p
      $('.export-all-btn').click() #export all files to .csv
    else if (e.altKey && e.ctrlKey && e.which == 80) #alt + ctrl + p
      webrep_export_selected_rows() #export selected files to .csv

  #Web Categorization - Complaints
  else if $('body').hasClass('escalations--webcat--complaints-controller')
    if (e.altKey && e.which == 84) #alt + t
      take_selected() #take ticket
    else if (e.altKey && e.which == 82) #alt + r
      return_selected() #return ticket†
    else if (e.altKey && e.shiftKey && e.which == 79) #alt + shift + o
      open_all() #open all
    else if (e.altKey && e.which == 79) #alt + o
      open_selected() #open ticket
    else if ( e.altKey && e.which == 70) #alt + f
      collapse_selected() #collapse selected tickets
    else if (e.altKey && e.which == 72) #alt + h
      collapse_all() #collapse all tickets
    else if (e.altKey && e.which == 68) #alt + d
      expand_selected() #expand selected tickets
    else if (e.altKey && e.which == 71) #alt + g
      expand_all() #expand all tickets