$ ->
  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax: $('#file-rep-datatable').data('source')
    pagingType: 'full_numbers'
    columns: [
      {data: 'status'}
      {data: 'sha256_hash'}
      {data: 'source'}
    ]


