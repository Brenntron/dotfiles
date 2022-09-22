$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
  categoryList = []

  $(document).ready(() ->
    AC.WebCat.getAUPCategories().then((categories) ->
      for key, value of categories
        cat_code = key.split(' - ')[1]
        value_name = key.split(' - ')[0]
        categoryList.push {category_id: value, category_name: value_name, category_code: cat_code}
    )
  )

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

        $('#domainHistoryDomainTableListingContent > .domain-data.result-total').remove()
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
                  if entry_id? && complain_id?
                    "<a href='/escalations/webcat/complaints/#{complaint_id}' target='_blank'>#{entry_id}</a>"
                  else
                    ''

              }
              {
                data: null
                className: 'domain-history-categories-cell'
                render: (data, type, full) ->
                  { category } = data

                  if category?
                    catIds = categoryList.filter((cat) -> category.indexOf(cat.category_name) >= 0).map((cat) -> cat.category_id)
                    return "<p data-catids='#{catIds}'>#{category}</p>"
                  else
                    ''
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

        if data.error?
          $('#xbrsHistoryLoader').hide()
          std_msg_error(data.error, [])
        else
          domainKey = Object.keys(data)[0]

          for entry in data[domainKey]
            entry.domain = domainKey

          data = data[domainKey]

          $('#xbrsHistoryLoader').hide()

          $('#xbrsDomainTableListingContent').append("<p class='domain-data result-total'>(#{data.length} found)</p>")
          $('#xbrsDomainTableListingContent > .domain-data.result-total').remove()

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
                  className: 'xbrs-history-categories-cell'
                  render: (data, type, full) ->
                    if data.aups.length > 0
                      cats = $.unique(data.aups.map((aup) -> aup.cat))

                      catIds = categoryList.filter((cat) -> cat.category_code in cats).map((cat) -> cat.category_id)
                      cats = cats.toString().split(',').join(', ')
                      return "<p data-catids='#{catIds}'>#{cats}</p>"
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

  $(document).on("click",'.xbrs-categorize-url-button', () ->
    button = $(this)
    categories = button.parent('td').siblings('.xbrs-history-categories-cell').find('p')
    { name, row } = button.data()

    if button.is(':checked')
      $('#xbrsHistorySelectedUrlsList').append("<li data-name='#{name}' data-row='#{row}'><p>#{name}</p><select id='xbrs-history-#{row}' class='input-group search-group' placeholder='Enter up to 5 categories' value=''></select></li>")
      $("#xbrs-history-#{row}").selectize {
        create: false,
        highlight: false,
        labelField: 'category_name',
        maxItems: 5,
        options: AC.WebCat.createSelectOptions("#xbrs-history-#{row}"),
        persist: true,
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }
      # An promise adds the options so we have to use an event handler to add the items.
      $("#xbrs-history-#{row}")[0].selectize.on('option_add', () ->
        catids = $(categories).data().catids
        if typeof catids is 'number'
          catids = [catids]
        else
          catids = catids.split(',')

        for catId in catids
          $("#xbrs-history-#{row}")[0].selectize.addItem(catId)
      )
    else
      $("#xbrsHistorySelectedUrlsList > li[data-row='#{row}']").remove()
  )

  $(document).on("click", '.domain-history-categorize-url-button', () ->
    button = $(this)
    categories = button.parent('td').siblings('.domain-history-categories-cell').find('p')
    { name, row } = button.data()

    if button.is(':checked')
      $('#domainHistoryTableSelectedUrlsList').append("<li data-name='#{name}' data-row='#{row}'><p>#{name}</p><select id='domain-history-#{row}' class='input-group search-group' placeholder='Enter up to 5 categories' value=''></select></li>")
      $("#domain-history-#{row}").selectize {
        create: false,
        highlight: false,
        labelField: 'category_name',
        maxItems: 5,
        options: AC.WebCat.createSelectOptions("#domain-history-#{row}"),
        persist: true,
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }

      # An promise adds the options so we have to use an event handler to add the items.
      $("#domain-history-#{row}")[0].selectize.on('option_add', () ->
        catids = $(categories).data().catids
        if typeof catids is 'number'
          catids = [catids]
        else
          catids = catids.split(',')
        for catId in catids
          $("#domain-history-#{row}")[0].selectize.addItem(catId)
      )
    else
      $("#domainHistoryTableSelectedUrlsList > li[data-row='#{row}']").remove()
  )

  checkAll = (headerCheckBox, tableId) ->
    checkAllValue = $(headerCheckBox).is(':checked')
    tableCheckBoxes = $(tableId).find('.categorize-url-button')
    urlList

    if tableId.indexOf('domainHistory') != -1
      urlList = $('#domainHistoryTableSelectedUrlsList')
      tableClassPrepend = 'domain-history'
    else
      urlList = $('#xbrsHistorySelectedUrlsList')
      tableClassPrepend = 'xbrs-history'

    for checkBox in tableCheckBoxes
      categories = $(checkBox).parent('td').siblings(".#{tableClassPrepend}-categories-cell").find('p')
      { name, row } = $(checkBox).data()

      $(checkBox).prop('checked', checkAllValue)

      if checkAllValue && (urlList.find("li[data-name='#{name}']").length is 0)
        # Row will change to the value of the last item in the loop so we have to capture the id.
        selectId = "#{tableClassPrepend}-#{row}"
        urlList.append("<li data-name='#{name}' data-row='#{row}'><p>#{name}</p><select id='#{selectId}' class='input-group search-group' placeholder='Enter up to 5 categories' value=''></select></li>")
        $("##{tableClassPrepend}-#{row}").selectize {
          create: false,
          highlight: false,
          labelField: 'category_name',
          maxItems: 5,
          options: AC.WebCat.createSelectOptions("##{tableClassPrepend}-#{row}"),
          persist: true,
          searchField: ['category_name', 'category_code'],
          valueField: 'category_id'
        }

        # An promise adds the options so we have to use an event handler to add the items.
        $("##{tableClassPrepend}-#{row}")[0].selectize.on('option_add', () ->
          catids = $(categories).data().catids
          if typeof catids is 'number'
            catids = [catids]
          else
            catids = catids.split(',')

          for catId in catids
            $("##{selectId}")[0].selectize.addItem(catId)
        )
      else if !checkAllValue && (urlList.find("li[data-name='#{name}']").length > 0)
        urlList.find("li[data-name='#{name}']").remove()

  $('#domainHistoryCheckAll').click(() ->
    checkAll(this, '#domainHistoryTableBody')
  )

  $('#xbrsHistoryCheckAll').click(() ->
    checkAll(this, '#xbrsHistoryTableBody')
  )

  window.apply_webcat_research_categories = (tab) ->
    listId = if tab == 'xbrs' then '#xbrsHistorySelectedUrlsList' else "#domainHistoryTableSelectedUrlsList"
    entries = []
    urlsListItems = $(listId).find('li')

    for listItem in urlsListItems
      entries.push $(listItem).data().name

    entries = $.unique(entries)

    for entry, index in entries
      category_ids = []
      categories = []
      urlsListItems = $(listId).find('li')
      selectize = $($(urlsListItems)[index]).find('select')[0].selectize

      for item in selectize.items
        category_ids.push item

        categories.push selectize.getItem(item)[0].innerText

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
          entries: [entry],
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
            std_msg_success('Categories Submitted', [], reload: false)
          else
            failed = data.complete_failed.concat data.create_failed
            std_msg_success('Categories were not created', failed, reload: false)
        error: (response) ->
          $('#webcat-research-categorize-url').dropdown('toggle')
          $('#webcat-research-categorize-urls .loader-gears').toggle()
          std_api_error(response, "Categories were not created.", reload: false)
      , this)
