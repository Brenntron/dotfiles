$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
  ongoing_detail_search = false
  ongoing_quick_search = false
  current_search_count = 0
  completed_counter = 0

  $(document).ready ->
    if window.location.pathname == '/escalations/webcat/research'
      update_tabs( window.location.hash )

  $('#research-tabs li').on 'click', ->
    update_tabs( window.location.hash )

  window.update_tabs = ( location ) ->
#    just making sure that correct loader is hidden/shown
#    having one and changing location has been less buggy/complicated than having 2 separate ones
    if location == '#domain-history'
      $('#xbrsHistoryPane').css('display', 'none')
      $('#domainHistoryLoader').removeClass('visible-ajax-message')
      $('#domainHistoryLoader').css('display','none')
      $('#domainHistoryPane').css('display', 'unset')
      if !ongoing_quick_search
        $('#xbrsHistoryLoader').removeClass('visible-ajax-message')
      else
        $('#xbrsHistoryLoader').addClass('visible-ajax-message')
      window.history.pushState("", "", '/escalations/webcat/research#domain-history')
    else if location == '#xbrs-history'
      $('#xbrsHistoryLoader').removeClass('visible-ajax-message')
      if !ongoing_detail_search
        $('#domainHistoryLoader').removeClass('visible-ajax-message')
        $('#domainHistoryPane').css('display', 'none')
        $('#xbrsHistoryPane').css('display', 'unset')
      else
        $('#domainHistoryLoader').addClass('visible-ajax-message')
        $('#xbrsHistoryPane').css('display', 'none')
