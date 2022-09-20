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
        { score, category } = parsedResponse.data

        if category.category_names
          spacedCategoryNames = category.category_names.toString().split(',').join(', ')

          $('#domainHistoryDomainTableCurrentCategoryContent').append("<p class='domain-data'>#{spacedCategoryNames}</p>")
          $('#xbrsDomainTableCurrentCategoryContent').append("<p class='domain-data'>#{spacedCategoryNames}</p>")
          $('#xbrsHistorySvg').show()
          $('#domainHistorySvg').show()
        else
          $('#xbrsDomainTableCurrentCategoryContent').append("<p class='domain-data missing-data'>#{'NA'}</p>")
          $('#domainHistoryDomainTableCurrentCategoryContent').append("<p class='domain-data missing-data'>#{'NA'}</p>")

        rep = wbrs_display(score)

        $('#domainHistorySvg').addClass("icon-#{rep}")
        $('#xbrsHistorySvg').addClass("icon-#{rep}")
        $('#domainHistorySvg').show()
        $('#xbrsHistorySvg').show()

        if score > 0
          $('#domainHistoryDomainName').attr("href", "https://#{domain}")
          $('#xbrsDomainName').attr("href", "https://#{domain}")
          $('#domainHistoryDomainName').attr('target', '_blank')
          $('#xbrsDomainName').attr('target', '_blank')
          $('#domainHistoryDomainName').removeClass('domain-name-normal')
          $('#xbrsDomainName').removeClass('domain-name-normal')

        if score % 1 == 0
          score = parseFloat(score).toFixed(1)

        $('#xbrsDomainTableReputation').append("<p class='domain-data'>#{score}</p>")
        $('#domainHistoryDomainTableReputation').append("<p class='domain-data'>#{score}</p>")
      error: (errorResponse) ->
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
        $('#domainHistoryDomainTableListingContent').append("<p class='domain-data result-total'>(#{data.length - 1} found)</p>")

        $('#domainHistoryLoader').hide()

        if $.fn.DataTable.isDataTable('.domain-history-table')
          $('.domain-history-table').DataTable().rows.add(data)
          $('.domain-history-table').DataTable().draw()
          $('#domain-history-table_wrapper').show()
        else
          $('.domain-history-table').DataTable({
            data: data
            dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
            columns: [
              {
                data: null
                render: (data, type, full, meta) ->
                  { url } = data
                  "<input type='checkbox' data-name='#{url}' data-row=#{meta.row} class='domain-history-categorize-url-button categorize-url-button'</input>"
                sortable: false
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

        $('#domain-history-table_filter input').addClass('table-search-input domain-table-search-label')

        $('#domainHistoryLoader').hide()
        $('.domain-history-table').show()
      error: (errorResponse) ->
        $('#domainHistoryLoader').hide()
        std_api_error(errorResponse, "Entries could not be retrieved.", reload: false)
    )

  getXbrsHistory = (domain) ->
    $.ajax(
      url: "/escalations/api/v1/escalations/webcat/complaints/get_xbrs_domain_history"
      method: 'GET'
      headers: headers
      data:
        domains: domain
      success: (response) ->
        data = JSON.parse response

        if data.code == 413
          $('#xbrsHistoryLoader').hide()
          std_msg_error(data.error, [])
        else
          domainKey = Object.keys(data)[0]

          for entry in data[domainKey]
            entry.domain = domainKey

          data = data[domainKey]

          $('#xbrsHistoryLoader').hide()

          $('#xbrsDomainTableListingContent').append("<p class='domain-data result-total'>(#{data.length} found)</p>")

          if $.fn.DataTable.isDataTable('#xbrs-history-table')
            $('#xbrs-history-table').DataTable().rows.add(data)
            $('#xbrs-history-table').DataTable().draw()
            $('#xbrs-history-table_wrapper').show()
          else
            $('#xbrs-history-table').DataTable({
              data: data
              dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
              columns: [
                {
                  data: null
                  render: (data, type, full, meta) ->
                    "<input type='checkbox' data-name='#{data.domain}' data-row='#{meta.row}' class='xbrs-categorize-url-button categorize-url-button'</input>"
                  sortable: false;
                }
                {
                  data: null
                  render: (data, type, full) ->
                    cats = data.aups.map((aup) -> aup.cat).filter((value, index, self) ->
                      self.indexOf(value) == index)

                    cats = cats.toString().split(',').join(', ')
                    return cats
                }
                {
                  data: 'domain'

                }
                {
                  data: null
                  render: (data, type, full) ->
                    { ruleHits } = data
                    ruleHits = ruleHits.toString().split(',').join(', ')
                    return ruleHits
                }
                {
                  data: null
                  render: (data, type, full) ->
                    { threatCats } = data
                    threatCats = threatCats.toString().split(',').join(', ')
                    return threatCats
                }
                {
                  data: null
                  render: (data, type, full) ->
                    { score } = data
                    rep = wbrs_display(score)

                    if score % 1 == 0
                      score = parseFloat(score).toFixed(1)

                    return "<span class='webcat-research-svg icon-#{rep}'></span><p>#{score}</p>"
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

            $('#xbrs-history-table_filter input').addClass('table-search-input domain-table-search-label')

            $('#xbrsHistoryLoader').hide()
            $('.xbrs-history-table').show()
      error: (errorResponse) ->
        $('#xbrsHistoryLoader').hide()
        std_api_error(errorResponse, "Entries could not be retrieved.", reload: false)
    )

  $('#webcat_research_search').on('keyup', (e) ->
    if e.key == 'Enter' || e.keyCode == 13
      domain = $(this).val()
      domain = domain.replace(/https\:\/\//, '')

      if domain
        $('#webcat_research_search').val(domain)
        $('#domainHistorySvg').hide()
        $('#domainHistorySvg').removeClass('icon-unkown icon-untrusted icon-questionable icon-neutral icon-favorable icon-trusted')
        $('#xbrsHistorySvg').hide()
        $('#xbrsHistorySvg').removeClass('icon-unkown icon-untrusted icon-questionable icon-neutral icon-favorable icon-trusted')
        $('.domain-data').remove()

        $('#xbrsDomainName').remove()
        $('#xbrsDomainTableListingContent').append("<a id='xbrsDomainName' class='domain-name domain-name-normal'>#{domain}</a>")
        $('#xbrs-history-table_wrapper').hide()
        $('.xbrs-history-table').hide()

        $('#domainHistoryDomainName').remove()
        $('#domainHistoryDomainTableListingContent').append("<a id='domainHistoryDomainName' class='domain-name domain-name-normal'>#{domain}</a>")
        $('#domain-history-table_wrapper').hide()
        $('.domain-history-table').hide()

        if $.fn.DataTable.isDataTable('.domain-history-table')
          $('.domain-history-table').DataTable().clear()

        if $.fn.DataTable.isDataTable('.xbrs-history-table')
          $('.xbrs-history-table').DataTable().clear()

        $('#domainHistoryLoader').css('display', 'flex')
        $('#xbrsHistoryLoader').css('display', 'flex')

        getDomainInfo(domain)
        getDomainHistory(domain)
        getXbrsHistory(domain)
  )

  $('#domain-history-webcat-research-categorize-url').click(() ->
    unless $('#domain-history-categorize-research-urls')[0].selectize
      $('#domain-history-categorize-research-urls').selectize {
        create: false,
        labelField: 'category_name',
        maxItems: 5,
        options: AC.WebCat.createSelectOptions('#domain-history-categorize-research-urls'),
        persist: true,
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }
  )

  $('#xbrs-history-webcat-research-categorize-url').click(() ->
    unless $('#xbrs-history-categorize-research-urls')[0].selectize
      $('#xbrs-history-categorize-research-urls').selectize {
        create: false,
        labelField: 'category_name',
        maxItems: 5,
        options: AC.WebCat.createSelectOptions('#xbrs-history-categorize-research-urls'),
        persist: true,
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }
  )

  $(document).on("click",'.xbrs-categorize-url-button', () ->
    button = $(this)
    { name, row } = button.data()

    if button.is(':checked')
      $('#xbrsHistorySelectedUrlsList').append("<li data-name='#{name}' data-row='#{row}'>#{name}</li>")
    else
      $("li[data-row='#{row}']").remove()
  )

  $(document).on("click", '.domain-history-categorize-url-button', () ->
    button = $(this)
    { name, row } = button.data()

    if button.is(':checked')
      $('#domainHistoryTableSelectedUrlsList').append("<li data-name='#{name}' data-row='#{row}'>#{name}</li>")
    else
      $("li[data-row='#{row}']").remove()
  )

  checkAll = (headerCheckBox, tableId) ->
    checkAllValue = $(headerCheckBox).is(':checked')
    tableCheckBoxes = $(tableId).find('.categorize-url-button')

    if tableId.indexOf('domainHistory') != -1
      urlList = $('#domainHistoryTableSelectedUrlsList')
      tableClassPrepend = 'domain-history'
    else
      urlList = $('#xbrsHistorySelectedUrlsList')
      tableClassPrepend = 'xbrs-history'

    for checkBox in tableCheckBoxes
      checkBoxDomain = $(checkBox).data().name
      $(checkBox).prop('checked', checkAllValue)

      if checkAllValue
        urlList.append("<li class='#{tableClassPrepend}-#{checkBoxDomain}'-selected-item>#{checkBoxDomain}</li>")
      else
        $(".#{tableClassPrepend}-#{checkBoxDomain}-selected-item").remove()

  $('#domainHistoryCheckAll').click(() ->
    checkAll(this, '#domainHistoryTableBody')
  )

  $('#xbrsHistoryCheckAll').click(() ->
    checkAll(this, '#xbrsHistoryTableBody')
  )

  window.apply_webcat_research_categories = (tab) ->
    listId = if tab == 'xbrs' then '#xbrsHistorySelectedUrlsList' else "#domainHistoryTableSelectedUrlsList"
    inputId = if tab == 'xbrs' then "#xbrs-history-categorize-research-urls" else "#domain-history-categorize-research-urls"
    buttonId = if tab == 'xbrs' then "#xbrs-history-webcat-research-categorize-url" else "#domain-history-webcat-research-categorize-url"
    entries = []
    category_ids = []
    categories = []
    urlsListItems = $(listId).find('li')

    for listItem in urlsListItems
      entries.push $(listItem).data().name

    entries = $.unique(entries)

    for id in $(inputId).val().split(',')
      category_ids.push id

      categories.push $(inputId)[0].selectize.getItem(id)[0].innerText

    if tab == 'xbrs'
      $("#xbrs-categorize-loader-gears").toggle()
      $('#xbrs-selected-urls-wrapper').toggle()
      $('#xbrs-selected-urls-categories-wrapper').toggle()
    else
      $("#domain-categorize-loader-gears").toggle()
      $('#domain-history-selected-urls-wrapper').toggle()
      $('#domain-history-selected-urls-categories-wrapper').toggle()

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

        if tab == 'xbrs'
          $("#xbrs-categorize-loader-gears").toggle()
          $('#xbrs-selected-urls-wrapper').toggle()
          $('#xbrs-selected-urls-categories-wrapper').toggle()
        else
          $("#domain-categorize-loader-gears").toggle()
          $('#domain-history-selected-urls-wrapper').toggle()
          $('#domain-history-selected-urls-categories-wrapper').toggle()

        unless data.complete_failed.length > 0 || data.create_failed.length > 0
          $(inputId)[0].selectize.clear()

          std_msg_success('Categories Submitted', [], reload: false)
        else
          failed = data.complete_failed.concat data.created_failed
          std_msg_success('Categories were not created', failed, reload: false)
      error: (response) ->
        $('#webcat-research-categorize-url').dropdown('toggle')
        $('#webcat-research-categorize-urls .loader-gears').toggle()
        std_api_error(response, "Categories were not created.", reload: false)
    , this)
