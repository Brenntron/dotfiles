$ ->
  file_rep_url = $('#file-rep-datatable').data('source')
  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data:
        search_type: 'advanced'
        search_name: 'shaky'
        search_conditions:
          status: 'shaky'
    pagingType: 'full_numbers'
    columns: [
      #{data: 'id'}
      {data: 'status'}
      #{data: 'file_name'}
      #{data: 'file_size'}
      {data: 'sha256_hash'}
      #{data: 'sample_type'}
      #{data: 'disposition'}
      #{data: 'disposition_suggested'}
      {data: 'source'}
      #{data: 'platform'}
      #{data: 'sandbox_score'}
      #{data: 'sandbox_threshold'}
      #{data: 'sandbox_under'} # true if score is under threshold
      #{data: 'sandbox_signer'}
      #{data: 'threatgrid_score'}
      #{data: 'threatgrid_threshold'}
      #{data: 'threatgrid_under'} # true if score is under threshold
      #{data: 'threatgrid_signer'}
      #{data: 'reversing_labs_score'}
      #{data: 'reversing_labs_signer'}
    ]


