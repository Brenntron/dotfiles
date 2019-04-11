$ ->

  file_rep_url = $('#file-rep-datatable').data('source')

  window.build_data = () ->
    search_type = window.get_search_type()
    search_name = window.get_search_name()

    data =
      search_type: search_type
      search_name: search_name
    return data


  window.get_search_type = () ->
    if !localStorage.search_type
      localStorage.search_type = 'standard'

    return localStorage.search_type


  window.get_search_name = () ->
    if localStorage.search_type = 'standard'
      current_url = window.location.href
      status_param_regex = /f=(.*)/
      current_name = status_param_regex.exec(current_url)
      if current_url.match('f=') && current_name
        # if the url has string that indicates a search param has been added,
        #ensure that localStorage search type matches current status
        localStorage.search_name = current_name[1]
      else
        localStorage.search_name = 'all'
    return localStorage.search_name

  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data: build_data()
#        search_conditions:
#          search_status: 'search_name'
#          search_name: 'search_name'
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


