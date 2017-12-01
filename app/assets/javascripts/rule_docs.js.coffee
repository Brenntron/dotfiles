$ ->
  table = $('#rule-docs-table').dataTable
    processing: true
    serverSide: true
    pageLength: 10
    ajax: $('#rule-docs-table').data('source')
    pagingType: 'full_numbers'
    columns: [
      {"width": "2%",data: 'sid'}
      {"width": "45%",data: 'summary'}
      {"width": "45%",data: 'details'}
      {"width": "6%",data: 'bugs'}
      {"width": "2%",data: 'links'}
    ]
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.
