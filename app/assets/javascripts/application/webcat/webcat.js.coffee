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
          '<a href="complaints/' + complaintID + '">' + complaintID + '</a>'

      }
      { data: 'entry_id' }
      { data: 'age' }
      { data: 'status' }
      { data: 'subdomain'
      }
      {
        'render':(data,type,full,meta)->
          domain = full.domain
          ip_address = full.ip_address
          if domain
            '<p>' + domain + '</p>'
          else
            '<a href="http://' + ip_address + '">' + ip_address + '</a>'

      }
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