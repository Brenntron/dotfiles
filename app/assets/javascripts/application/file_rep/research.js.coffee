$ ->
#  if $('.active').attr('tab') == 'research'
#  This should be wrapped in a window function and called on page load/page refresh, but it keeps breaking when I try to
#window.threatgrid_data = () ->
  sha256_hash = $('#sha256_hash')[0].innerText
  std_msg_ajax(
    method: 'POST'
    url: "/escalations/api/v1/escalations/filerep/research/"
    data: {sha256_hash: sha256_hash}
    success_reload: false
    success: (response) ->
#      debugger
      if response.json.data.current_item_count > 0
        file_data = response.json.data.items[0].item
        console.log file_data

        # Load the top data
        $('#tg-submission-date').text(file_data.submitted_at)
        $('#tg-run-status').text(file_data.state)
        $('#tg-score').text(file_data.analysis.threat_score)
        $('#tg-tags').text(file_data.tags.join(', '))

        console.log file_data.analysis.behaviors
        # Adding behaviors
        behaviors = ""
        $(file_data.analysis.behaviors).each ->
          behaviors += '<tr>'
          behaviors += '<td>' + this.name + '</td><td>' + this.threat + '</td><td>' + this.title + '</td>'
          behaviors += '</tr>'
        $('#tg-behaviors').append('<tbody>' + behaviors + '</tbody>')

        # Adding full json report in case it's needed
        full_report = JSON.stringify(response, null, '\t')
        $('#tg-full').text(full_report)


      else
#        Show the button to push to threatgrid
        console.log 'we need to push to threatgrid'

    error: (response) ->
      std_api_error(response, "There was a problem retrieving the research data.", reload: false)
  )



