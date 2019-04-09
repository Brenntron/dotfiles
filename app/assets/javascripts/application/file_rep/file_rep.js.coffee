$ ->

  file_rep_url = $('#file-rep-datatable').data('source')

  window.get_search_type = () ->
    if !localStorage.search_type
      localStorage.setItem("search_type", "standard")

    return localStorage.search_type

  window.get_search_name = () ->
    localStorage.search_name = 'katie'
    return localStorage.search_name

  window.get_search_status = () ->
    current_url = window.location.href
    status_param_regex = /f=(.*)/
    current_status = status_param_regex.exec(current_url)[1]

    if current_url.match('f=')
      localStorage.search_status = current_status
        # if the url has string that indicates a search param has been added,
        #ensure that localStorage search type matches current status
    else
      localStorage.search_status ='all'

    return localStorage.search_status


  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data:
        search_type: window.get_search_type()
        search_name: 'Katie'
        search_conditions:
          status: window.get_search_status()
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


