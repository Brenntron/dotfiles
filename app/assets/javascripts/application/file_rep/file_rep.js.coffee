$ ->

  file_rep_url = $('#file-rep-datatable').data('source')

  window.get_search_name = () ->
    current_url = window.location.href
    search_param_regex = /f=(.*)/
    filter_rep_search_name = 'all'

    if current_url.match('f=')
      # if the url has string that indicates a search param has been added, return the search param
      filter_rep_search_name = search_param_regex.exec(current_url)[1]

    return filter_rep_search_name

  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data:
        search_type: 'advanced'
        search_name: get_search_name()
        search_conditions:
          status: 'shaky'
    pagingType: 'full_numbers'
    columns: [
      #{data: 'id'}
      #{data: 'created_at'}
      #{data: 'updated_at'}
      {data: 'status'}
      #{data: 'resolution'}
      #{data: 'assigned'}
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
      #{data: 'detection_name'}
      #{data: 'detection_created_at'}
      #{data: 'in_zoo'}
      #{data: 'threatgrid_score'}
      #{data: 'threatgrid_threshold'}
      #{data: 'threatgrid_under'} # true if score is under threshold
      #{data: 'threatgrid_signer'}
      #{data: 'reversing_labs_score'}
      #{data: 'reversing_labs_signer'}
      #{data: 'customer_name'}
      #{data: 'customer_email'}
      #{data: 'customer_company_name'}
    ]


