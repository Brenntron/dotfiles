$ ->
  $('#rule-docs-table').dataTable
    'dom': '<<"toolbar" lf><t>ip>'
    language: {
      searchPlaceholder: 'Search rules'
    }
    processing: true
    serverSide: true
    pageLength: 10
    ajax: $('#rule-docs-table').data('source')
    pagingType: 'full_numbers'
    responsive: true
    columns: [
      {
        data: 'sid'
      }
      {
        data: 'summary'
        orderable: false
      }
      {
        data: 'details'
        orderable: false
      }
      {
        data: 'bugs'}
      {
        data: 'links'
        class: 'td-tools'
        orderable: false
      }
    ]
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.
