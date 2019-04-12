$ ->
  if $('.active').attr('tab') == 'research'

    sha256_hash = $('#sha256_hash')[0].innerText

    std_msg_ajax(
      method: 'POST'
      url: "/escalations/api/v1/escalations/filerep/research/"
      data: {sha256_hash: sha256_hash}
      success_reload: false
      success: (response) ->
      error: (response) ->
        std_api_error(response, "There was a problem retrieving the research data.", reload: false)
    )
