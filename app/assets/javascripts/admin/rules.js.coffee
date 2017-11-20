$ ->
  $('#rules-table').dataTable
    processing: true
    serverSide: true
    pageLength: 25
    ajax: $('#rules-table').data('source')
    pagingType: 'full_numbers'
    columns: [
      {data: 'id'}
      {data: 'sid'}
      {data: 'message'}
      {data: 'bug_count'}
      {data: 'state'}
      {data: 'edit_status'}
      {data: 'publish_status'}
      {data: 'links'}
    ]
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.
