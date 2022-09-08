$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()

  getDomainInfo = (domain) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints/domain_info'
      method: 'GET'
      headers: headers
      data:
        domain: domain
      success: (response) ->
        parsedResponse = JSON.parse response
        data = parsedResponse.data

        if data.category.category_names
          $('.domain-table-current-category-content').append("<p class='domain-data'>#{data.category.category_names.toString()}</p>")
          $('.domain-table-current-category-content .webcat-research-svg').show()
        else
          $('.domain-table-current-category-content').append("<p class='domain-data missing-data'>#{'NA'}</p>")

        rep = wbrs_display(data.score)

        $('.domain-table-reputation-content span.webcat-research-svg').addClass("icon-#{rep}")
        $('.domain-table-reputation-content span.webcat-research-svg').show()

        if data.score > 0
          $('.domain-name').remove()
          $('.domain-table-listing-content').append("<a class='domain-name' href='https://#{domain}' target='_blank'>#{domain}</a>")

        $('.domain-table-reputation-content').append("<p class='domain-data'>#{data.score}</p>")
      error: (response) ->
        std_api_error(errorResponse, "Domain info could not be retrieved.", reload: false)
    )

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
        $('.domain-table-listing-content').append("<p class='domain-data result-total'>(#{data.length - 1} found)</p>")

        $('.ajax-message-div').hide()

       #for entry, index in data
       #  table_row = "<tr><td><input type='checkbox' name='#{entry.url}' class='categorize-url-button'</input>" + (if entry.entry_id then "<td><a href='/escalations/webcat/complaints/#{entry.complaint_id}' target='_blank'>#{entry.entry_id}</a></td>" else "<td></td>") + "<td>#{entry.category || ''}</td>" + (if entry.score >= 0 then "<td><a href='https://#{entry.url}' target='_blank' class='domain-history-link'>#{entry.url}</a></td>" else "<td>#{entry.url}</td>") + "<td>#{entry.time_of_action || ''}</td><td class='domain-history-action'>#{entry.action || ''}</td><td>#{entry.confidence || ''}</td><td>#{entry.description}</td><td>#{entry.user || ''}</td></tr>"
       #  $('#domainHistoryTableBody').append(table_row)
        $('.domain-history-table').DataTable({
          data: data
          dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
          columns: [
            {
              data: null
              className: 'webcat-research-checkbox'
              render: (data, type, full) ->
                { url } = data
                "<input type='checkbox' name='#{url}' class='categorize-url-button'</input>"
            }
            {
              data: null
              render: (data, type, full) ->
                { entry_id, complaint_id } = data
                if entry_id
                  "<a href='/escalations/webcat/complaints/#{complaint_id}' target='_blank'>#{entry_id}</a>"
                else
                  entry_id

            }
            {
              data: 'category'
            }
            {
              data: null
              render: (data, type, full) ->
                { url, score } = data

                if score >= 0
                  "<a href='https://#{url}' target='_blank' class='domain-history-link'>#{url}</a>"
                else
                  url
            }
            {
              data: 'time_of_action'
            }
            {
              data: 'action'
            }
            {
              data: 'confidence'
            }
            {
              data: 'description'
            }
            {
              data: 'user'
            }
          ]
          language: {
            search: "_INPUT_"
            searchPlaceholder: "Search within table"
          }
          lengthMenu: [50, 100, 200]
          order: [ [
            3
            'desc'
          ] ]
          pagingType: 'full_numbers'
        })

        $('#complaints-index_filter input').addClass('restricted-table-search-input');
        $('#DataTables_Table_0_filter').addClass('domain-table-search-label')

        $('.ajax-message-div').hide()
        $('.domain-history-table').show()
      error: (errorResponse) ->
        $('.ajax-message-div').hide()
        $('.domain-history-table').show()
        std_api_error(errorResponse, "Entries could not be retrieved.", reload: false)
    )

  $(document).ready(
    hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&')
    domain = hashes[0].split('=')[1]

    if domain
      $('#webcat_research_search').val(domain)
      $('.domain-table-listing-content').append("<p class='domain-name'>#{domain}</p>")
      $('.ajax-message-div').show()

      getDomainInfo(domain)
      getDomainHistory(domain)
  )

  $('#webcat_research_search').on('keyup', (e) ->
    if e.key == 'Enter' || e.keyCode == 13
      domain = $(this).val()
      domain = domain.replace(/https\:\/\//, '')

      if domain
        url = window.location.origin + window.location.pathname + "?domain=#{domain}"
      else
        url = window.location.origin + window.location.pathname

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

    $('#webcat-research-categorize-urls .loader-gears').toggle()
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
        $('#webcat-research-categorize-urls .loader-gears').toggle()
        unless data.complete_failed.length > 0 || data.create_failed.length > 0
          $('#categorize-research-urls')[0].selectize.clear()

          std_msg_success('Categories Submitted', [], reload: false)
        else
          std_msg_success('Categories were not created', [], reload: false)
      error: (response) ->
        $('#webcat-research-categorize-url').dropdown('toggle')
        $('#webcat-research-categorize-urls .loader-gears').toggle()
        std_api_error(response, "Categories were not created.", reload: false)
    , this)

