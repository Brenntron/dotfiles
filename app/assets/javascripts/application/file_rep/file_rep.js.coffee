$ ->
  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax: $('#file-rep-datatable').data('source')
    pagingType: 'full_numbers'
    columns: [
      {data: 'name'}
      {data: 'sha256'}
      {data: 'email'}
    ]


