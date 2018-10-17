window.populate_clusters_index_table = (filter) ->
#  alert 'Fuck'
  filter_param = ""
  if filter
    filter_param = "?regex=" + filter

  #body.index-action may need to change depending on how it's all coded up
#  if $('#clusters-index').length
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/clusters" + filter_param
    method: 'GET'
    headers: headers
    success: (response) ->

      json = $.parseJSON(response)


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

window.categorize_cluster = (cluster_id, comment, category_ids) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: "/escalations/api/v1/escalations/webcat/clusters/process_cluster"
    method: 'POST'
    headers: headers
    data: {cluster_id: cluster_id, category_ids: category_ids, comment: comment}
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        #notice_html = "<p>Something went wrong: #{json.error}</p>"
        #alert(json.error)
      else

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      #$("#create_research_submit_wait").addClass('hidden').hide()
      #$("#create_research_submit").show()
  , this)

$ ->
  $(document).ready ->
    window.copycat_dialog = (value) ->
      $('#whois_dialog').dialog({
        dialogClass: "whois_tool_dialog"
      })
      $('input.whois-input-holder')[0].value = value
      return
    window.clearInputField = (fieldname) ->
      $('input.' + fieldname)[0].value = ''
    window.pasteDomain = (fieldname) =>
      value = $('input.whois-input-holder')[0].value
      $('input.' + fieldname)[0].value = value


    clusters_table = $('#clusters-index').DataTable(
      columnDefs: [
        {
          targets: [
            0
            1
          ]
          orderable: false
          searchable: false
        }
        {
          targets: [ 0 ]
          className: 'expandable-row-column'
        }
      ]
      columns: [
        {
          data: null
          defaultContent: '<button class="expand-row-button-inline"></button>'
        }
        {
          data: 'cluster_id'
          render: (data) ->
            '<input type="checkbox" name="cbox" class="cluster_check_box" id="cbox' + data + '" value="' + data + '" />'
        }
        {
          data: 'cluster_id'
        }
        {
          data: 'domain',
          render: (data) ->
            regexp = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/i;
            if (data.match(regexp))
              data
            else
              if (data.startsWith('http') is false)
                data = 'http://' + data
                '<button type="button" class="help-btn right-margin esc-tooltipped" title="Whois Domain Lookup Information" onclick="copycat_dialog(\'' + data + '\')"></button>' +
                '<button type="button" class="google-btn right-margin esc-tooltipped" title="Google it!" onclick="window.open(\'https://www.google.com/search?q=' + data + '\')"></button>' +
                data + '<button type="button" onclick="window.open(\'' + data + '\', \'_blank\') " class="data-btn right-margin esc-tooltipped", title="Open ' + data + ' in a new tab"></button>'
        }
        {
          data: 'global_volume'
        }
        {
          data: null
          defaultContent: 'N/A'
        }
        {
          data: 'ctime'
        }
        {
          data: 'now'
        }
        {
          data: 'age'
        }
      ]
    )
    window.populate_clusters_index_table()
