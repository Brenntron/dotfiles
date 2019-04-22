$(document).ready ->

  $('.fr-ticket-status-radio-label').click ->
    radio_button = $(this).prev('.fr-ticket-status-radio')
    $(radio_button[0]).trigger('click')
    if $(radio_button).attr('id') == 'file-status-closed'
      $('#show-ticket-resolution-submenu').show()
      stat_comment = $('#ticket-non-res-submit').find('.ticket-status-comment')
      $('#ticket-non-res-submit').hide()
      $(stat_comment).val('')
    else
      $('#ticket-non-res-submit').show()
      res_comment = $('.resolution-comment-wrapper').find('.ticket-status-comment')
      $('.ticket-resolution-radio').prop('checked', false)
      $('#show-ticket-resolution-submenu').hide()
      $(res_comment[0]).val('')
