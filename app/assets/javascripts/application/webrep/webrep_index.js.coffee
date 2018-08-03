#Populating the toolbar Adjust WL/BL Button
window.index_expand_wlbl_form = () ->
  if ($('.dispute-entry-checkbox:checked').length > 0)
    $('.dispute-entry-checkbox:checked').each ->
      entry_row = this.closest('tr')
      entry_content = $(entry_row).find('.dispute_entry_content_first').text()
      #wbrs = $(entry_row).find('.entry-data-wbrs-score').text()
      #wlbl = $(entry_row).find('.entry-data-wlbl').text()

      tbody = $('#wlbl_adjust_entries').find('tbody')
      $(tbody[0]).append('<tr><td>' + entry_content + '</td><td class="no-word-break">' + '' + '</td><td class="text-center">' + '' + '</td></tr>')

    $($('#wlbl_adjust_entries').find('.comment-wrapper')).show()
    $('#wlbl_adjust_entries').show();

  else
    alert ('No rows selected')
