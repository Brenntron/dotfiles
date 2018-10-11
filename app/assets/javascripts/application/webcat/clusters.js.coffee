window.populate_clusters_index_table = (filter) ->
#  alert 'Fuck'
  filter_param = ""
  if filter
    filter_param = "?regex=" + filter

  #body.index-action may need to change depending on how it's all coded up
  if $('#clusters-index').length
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/clusters" + filter_param
      method: 'GET'
      headers: headers
#      data: data
#      data_json: JSON.stringify(data)
      success: (response) ->
#        debugger
        json = $.parseJSON(response)
        console.log json.data

        if json.data.length == 0
          std_msg_error("No clusters available.","")

        if json.error
          notice_html = "<p>Something went wrong: #{json.error}</p>"
          alert(json.error)
        else

          datatable = $('#clusters-index').DataTable()
          datatable.clear();

          datatable.rows.add(json.data);
          datatable.draw();

      error: (response) ->
        notice_html = "<p>Something went wrong: #{response.responseText}</p>"
        #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
        #$("#create_research_submit_wait").addClass('hidden').hide()
        #$("#create_research_submit").show()
    , this)

window.fetch_cluster_data = (id) ->
  std_msg_ajax(
    method: 'GET'
    url: "/escalations/api/v1/escalations/webcat/clusters/" + id
    data: {}
    success: (response) ->
      #$('#loader-modal').hide()
      json = $.parseJSON(response)
      json.data
      console.log (json.data)
    error: (response) ->
      #$('#loader-modal').hide()
      #$('.modal-backdrop').remove()
  )


$ ->
  $(document).ready ->
