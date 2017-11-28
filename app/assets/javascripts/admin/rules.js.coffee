$ ->
  $('#rules-table').dataTable(
    'dom': '<<"toolbar" lf><t>ip>'
    processing: true
    serverSide: true
    pageLength: 25
    ajax: $('#rules-table').data('source')
    pagingType: 'full_numbers'
    responsive: true
    columns: [
      {data: 'id'}
      {data: 'sid'}
      {
        data: 'message'
        orderable: false
        render: (data) ->
          '<span class="code-snippet">' + data + '</span>'
      }
      {data: 'bug_count', class: 'col-nowrap'}
      {
        data: 'state'
        render: (data) ->
          '<span class="emphasis">' + data + '</span>'
      }
      {data: 'edit_status', class: 'col-nowrap'}
      {data: 'publish_status', class: 'col-nowrap'}
      {
        data: 'links', class: 'td-tools'
        orderable: false
      }
    ])
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.
