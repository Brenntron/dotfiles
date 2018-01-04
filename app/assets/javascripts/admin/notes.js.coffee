$ ->
  $('#notes-table').dataTable(
    'dom': '<<"toolbar" lf><t>ip>'
    language: {
      searchPlaceholder: 'Search notes'
    }
    processing: true
    serverSide: true
    pageLength: 25
    ajax: $('#notes-table').data('source')
    pagingType: 'full_numbers'
    responsive: true
    columns: [
      {data: 'id'}
      {data: 'bug_id'}
      {
        data: 'note_type'
        render: (data) ->
          '<span class="emphasis">' + data + '</span>'
      }
      {
        data: 'comment'
        orderable: false
        render: (data) ->
          '<span class="code-snippet">' + data + '</span>'
      }
      {data: 'author', class: 'col-nowrap'}
      {data: 'notes_bugzilla_id', class: 'col-nowrap'}
      {data: 'created_at', class: 'col-nowrap'}
      {data: 'updated_at', class: 'col-nowrap'}
      {
        data: 'links', class: 'td-tools'
        orderable: false
      }
    ])
# pagingType is optional, if you want full pagination controls.
# Check dataTables documentation to learn more about
# available options.
