$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  getDomainHistory = (domain) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/get_domain_history'
      method: 'GET'
      headers: headers
      data:
        domain: domain
      success: (response) ->
        data = response.data

        #the first entry is the domain itself so that should not count in the result total
        $('.domain-table-listing').append("<p class='result-total'>(#{data.length - 1} found)</p>")

        if data[0].category
          $('.domain-table-current-category').append("<p>#{data[0].category}</p>")
          $('#categoryCheck').show()
        else
          $('.domain-table-current-category').append("<p class='missing-data'>#{'NA'}</p>")
          $('#categoryCheck').hide()

        if data[0].score.indexOf('no data') != -1
          $('.domain-table-reputation').addClass('missing-data')
        else if data[0].score > 0
          $('#redX').hide()
          $('#greenCheck').show()
        else if data[0].score < 0
          $('#redX').show()
          $('#greenCheck').hide()

        $('.domain-table-reputation').html("#{data[0].score}")

        for entry, index in data
          #the first entry is the domain itself so that should be skipped
          if index != 0
            table_row = "<tr><th><input type='checkbox' name='#{entry.url}' class='categorize-url-button'</input><th>#{entry.entry_id || ''}</th><th>#{entry.category}</th><th class='domain-history-url'>#{entry.url}</th><th>#{entry.time_of_action}</th><th>#{entry.action}</th><th>#{entry.confidence}</th><th>#{entry.description}</th><th>#{entry.user}</th></tr>"
            $('#domainHistoryTableBody').append(table_row)
      error: (errorResponse) ->
        std_api_error(errorResponse, "Entries could not be retrieved.", reload: false)
    )

  $(document).ready(
    hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&')
    domain = hashes[0].split('=')[1]

    if domain
      $('#webcat_research_search').val(domain)
      $('.domain-table-listing').append("<p class='domain-name'>#{domain}</p>")

      getDomainHistory(domain)
  )

  $('#webcat_research_search').on('keyup', (e) ->
    if e.key == 'Enter' || e.keyCode == 13
      domain = $(this).val()
      hash = window.location.hash.split('?')[0]
      url = window.location.origin + window.location.pathname + "?domain=#{domain}"
      document.location.assign(url)
  )

  $('#webcat-research-categorize-url').click(() ->
    $('#categorize-research-urls').selectize {
      create: false,
      labelField: 'category_name',
      maxItems: 5,
      options: AC.WebCat.createSelectOptions('#categorize-research-urls'),
      persist: true,
      searchField: ['category_name', 'category_code'],
      valueField: 'category_id'
    }
  )

  window.apply_webcat_research_categories = () ->
    domain = $('#webcat_research_search').val()
    entries = [ domain ]
    category_ids = []
    categories = []

    for id in $('#categorize-research-urls').val().split(',')
      category_ids.push id

      categories.push $('#categorize-research-urls')[0].selectize.getItem(id)[0].innerText

    $('.loader-gears').toggle()
    $('.selected-urls-wrapper').toggle()
    $('.selected-urls-categories-wrapper').toggle()

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints/bulk_categorize'
      method: 'POST'
      headers: headers
      data:
        entries: entries,
        category_ids: category_ids,
        categories: categories
      success: (response) ->
        data = response.data

        $('#webcat-research-categorize-url').dropdown('toggle')
        $('.loader-gears').toggle()
        unless data.complete_failed.length > 0 || data.create_failed.length > 0
          $('#categorize-research-urls')[0].selectize.clear()

          std_msg_success('Categories Submitted', [], reload: false)
        else
          std_msg_success('Categories were not created', [], reload: false)
      error: (response) ->
        $('#webcat-research-categorize-url').dropdown('toggle')
        $('.loader-gears').toggle()
        std_api_error(response, "Categories were not created.", reload: false)
    , this)

