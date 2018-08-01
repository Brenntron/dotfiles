$('#myModal').on 'shown.bs.modal', ->
  $('#myInput').trigger 'focus'
$ ->
  complaint_table = $('#complaints-index').DataTable(
    'rowCallback': (row, data, index) ->
      $node = @api().row(row).nodes().to$()
      $node.addClass 'not-shown'
      if  data.subdomain && data.subdomain.length > 0
        $node.addClass 'highlight-has-subdomain'
      if data.is_important
        $node.addClass 'highlight-second-review'
      if data.age_int < 10800
        $node.addClass 'highlight-minus3Hours'
      else if data.age_int < 18000
        $node.addClass 'highlight-minus5Hours'
      else if data.age_int > 18000
        $node.addClass 'highlight-plus5Hours'
      else
      return
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
      {
        targets: [ 2 ]
        className: 'id-col'
        'width': '1%'
      }
      {
        targets: [ 3 ]
        className: 'entry-id-col'
        'width': '1%'
      }
    ]
    columns: [
      {
        data: null
        defaultContent: '<button class="expand-row-button-inline"></button>'
      }
      {
        data: null
        defaultContent: '<p class="">icons</p>'
      }
      {
        sortable: false
        'render': (data, type, full, meta) ->
          complaintID = full.complaint_id.toString()
          '<a href="' + complaintID + '">' + complaintID + '</a>'

      }
      { data: 'entry_id' }
      { data: 'age' }
      { data: 'status' }
      { data: 'subdomain' }
      { data: 'domain' }
      { data: 'path' }
      { data: 'customer_name' }
      { data: 'wbrs_score' }
      { data: 'category' }
      { data: 'assigned_to' }
    ]
    select: 'style': 'os'
    responsive: true)
  populate_webcat_index_table()
  $('#complaints-index tbody').on 'click', 'td.expandable-row-column', ->
    click_table_buttons complaint_table, this


  $('#cat_new_url').selectize {
    persist: false,
    create: false,
    maxItems: 5
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: AC.WebCat.createSelectOptions()

  }

  $('#general_search').on 'keyup', (e) ->
    if event.keyCode == 13
      # do the ajax call
      filter = this.value
      headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
      $.ajax(
        url: '/api/v1/escalations/webcat/complaint_entries?search='+filter
        method: 'GET'
        headers: headers
        success: (response) ->

          json = $.parseJSON(response)
          if json.error
            notice_html = "<p>Something went wrong: #{json.error}</p>"
            alert(json.error)
          else
            datatable = $('#complaints-index').DataTable()
            datatable.clear();
            datatable.rows.add(json.data);
            datatable.draw();

        error: (response) ->
          std_api_error(response, "There was an error loading search results.", reload: false)
      , this)
