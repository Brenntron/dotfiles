$ ->
  headers =  'Token': $('input[name="token"]').val(),'Xmlrpc-Token': $('input[name="xml_token"]').val()
  categoryList = []
  xbrsSelectLimiter = 0
  domainHistorySelectLimiter = 0

  setDhSelectLimiter = (term) ->
    domainHistorySelectLimiter += term

  getDhSelectLimiter = () ->
    domainHistorySelectLimiter

  setXbrsSelectLimiter = (term) ->
    xbrsSelectLimiter += term

  getXbrsSelectLimiter = () ->
    xbrsSelectLimiter

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
        'domain': domain
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

        getDomainHistory(domain)
        getXbrsHistory(domain)
      error: (errorResponse) ->
        std_api_error(errorResponse, "Domain info for #{domain} could not be retrieved.", reload: false)
        $('#domainHistoryLoader').hide()
        $('#xbrsHistoryLoader').hide()
    )

  getDomainHistory = (domain) ->
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/complaint_entries/get_domain_history'
      method: 'GET'
      headers: headers
      data:
        'domain': domain
      success: (response) ->
        data = response.data

        $('#domainHistoryLoader').hide()

        $('#domainHistoryDomainTableListingContent > .domain-data.result-total').remove()
        #the first entry is the domain itself so that should not count in the result total
        $('#domainHistoryDomainTableListingContent').append("<p class='domain-data result-total'>(#{data.length - 1} found)</p>")

        if $.fn.DataTable.isDataTable('.domain-history-table')
          $('.domain-history-table').DataTable().rows.add(data)
          $('.domain-history-table').DataTable().draw()
          $('#domain-history-table_wrapper').show()
          $('.domain-history-table').show()
        else
          $('.domain-history-table').DataTable({
            data: data
            dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
            columns: [
              {
                data: null
                className: 'domain-history-checkbox'
                render: (data) ->
                  { url } = data
                  formattedUrl = url.replace(/\/|\./g, '-').replace(/\</g, '&lt;').replace(/\>/g, '&gt;').replace(/\<|\>|\(|\)/g, '')

                  "<input type='checkbox' data-name='#{formattedUrl}' data-url='#{url.replace(/\</g, '&lt;').replace(/\>/g, '&gt;').replace(/\<|\>|\(|\)/g, '')}' class='domain-history-categorize-url-button categorize-url-button'</input>"
                sortable: false
              }
              {
                data: null
                defaultContent: '<span></span>'
                orderable: false
                render: ( data ) ->
                  { is_important } = data

                  if is_important
                    return '<div class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></div>'
                searchable: false
                sortable: false
                width: '10px'
              }
              {
                data: null
                render: (data) ->
                  { entry_id, complaint_id } = data
                  if entry_id? && complaint_id?
                    "<a href='/escalations/webcat/complaints/#{complaint_id}' target='_blank'>#{entry_id}</a>"
                  else
                    ''

              }
              {
                data: null
                className: 'domain-history-categories-cell'
                render: (data, type, full, meta) ->
                  { category, url } = data

                  if category?
                    return "<p data-name='#{url.replace(/\<|\>|\(|\)/g, '')}''>#{category}</p>"
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
        $('#domain-history-table_wrapper').show()
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
        'domains': domain
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
            $('#xbrs-history-table').show()
          else
            $('#xbrs-history-table').DataTable({
              data: data
              dom: '<"datatable-top-tools no-margin-datatable-top-tool"lf>t<ip>'
              columns: [
                {
                  data: null
                  className: 'xbrs-history-checkbox'
                  render: (data) ->
                    formattedDomain = data.domain.replace(/\/|\./g, '-').replace(/\</g, '&lt;').replace(/\>/g, '&gt;').replace(/\<|\>/g, '')

                    "<input type='checkbox' data-name='#{formattedDomain}' data-url='#{data.domain.replace(/\</g, '&lt;').replace(/\>/g, '&gt;').replace(/\<|\>|\(|\)/g, '')}' class='xbrs-categorize-url-button categorize-url-button'</input>"
                  sortable: false
                }
                {
                  data: null
                  defaultContent: '<span></span>'
                  orderable: false
                  render: ( data ) ->
                    { is_important } = data

                    if is_important
                      return '<div class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></div>'
                  searchable: false
                  sortable: false
                  width: '10px'
                }
                {
                  data: null
                  className: 'xbrs-history-categories-cell'
                  render: (data) ->
                    if data.aups.length > 0
                      cats = $.unique(data.aups.map((aup) -> aup.cat)).toString().split(',').join(', ')
                      return "<p data-name='#{data.domain.replace(/\<|\>|\(|\)/g, '')}'>#{cats}</p>"
                    else
                      ''
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
            $('.xbrs-history-table_wrapper').show()
            $('.xbrs-history-table').show()
      error: (errorResponse) ->
        $('#xbrsHistoryLoader').hide()
        std_api_error(errorResponse, "Entries could not be retrieved.", reload: false)
    )

  removeCategoryUrlItems = () ->
    xbrsUrlList = $('#xbrsHistorySelectedUrlsList')
    dhUrlList = $('#domainHistoryTableSelectedUrlsList')

    $('#xbrsHistoryCheckAll').prop('checked', false)
    $('#domainHistoryCheckAll').prop('checked', false)

    for item in xbrsUrlList.find('li')
      { name } = $(item).data().name
      $(item).remove()
      $(".xbrs-history-checkbox > input[data-name='#{name}']").prop('checked', false)
      xbrsSelectLimiter -= 1

    for item in dhUrlList.find('li')
      { name } = $(item).data().name
      $(item).remove()
      $(".domain-history-checkbox > input[data-name='#{name}']").prop('checked', false)
      domainHistorySelectLimiter -= 1

    $('#xbrs-history-webcat-research-categorize-url').attr('disabled', 'disabled')
    $('#domain-history-webcat-research-categorize-url').attr('disabled', 'disabled')

  $('#webcat_research_search').on('keyup', (e) ->
    if e.key == 'Enter' || e.keyCode == 13
      domain = $(this).val()
      domain = domain.replace(/https\:\/\//, '').replace(/http\:\/\//, '')

      if domain
        $('#webcat_research_search').val(domain)
        $('#domainHistorySvg').hide()
        $('#domainHistorySvg').removeClass('icon-unkown icon-untrusted icon-questionable icon-neutral icon-favorable icon-trusted')
        $('#xbrsHistorySvg').hide()
        $('#xbrsHistorySvg').removeClass('icon-unkown icon-untrusted icon-questionable icon-neutral icon-favorable icon-trusted')
        $('.domain-data').remove()

        domain = domain.replace(/\</g, '&lt;').replace(/\>/g, '&gt;')

        $('#xbrsDomainName').remove()
        $('#xbrsDomainTableListingContent').append("<a id='xbrsDomainName' class='domain-name domain-name-normal'>#{domain}</a>")
        $('#xbrs-history-table_wrapper').hide()
        $('#xbrs-history-table').hide()

        $('#domainHistoryDomainName').remove()
        $('#domainHistoryDomainTableListingContent').append("<a id='domainHistoryDomainName' class='domain-name domain-name-normal'>#{domain}</a>")
        $('#domain-history-table_wrapper').hide()
        $('.domain-history-table').hide()

        removeCategoryUrlItems()

        if $.fn.DataTable.isDataTable('.domain-history-table')
          $('.domain-history-table').DataTable().clear()

        if $.fn.DataTable.isDataTable('.xbrs-history-table')
          $('.xbrs-history-table').DataTable().clear()

        $('#domainHistoryLoader').css('display', 'flex')
        $('#xbrsHistoryLoader').css('display', 'flex')

        getDomainInfo(domain)
  )

  $(document).on("click",'.xbrs-categorize-url-button', () ->
    button = $(this)
    data = button.data()

    name = data.name.replace(/\<|\>|\(|\)/g, '')
    url = data.url.replace(/\<|\>|\(|\)/g, '')

    if button.is(':checked') && xbrsSelectLimiter < 10 && ($("#xbrsHistorySelectedUrlsList > li[data-name='#{name}'").length is 0)
      selectize_url_li =
        "<li data-name='#{name}' data-url='#{url}'>#{url}" +
        "<select id='xbrs-history-#{name}' class='form-control selectize' placeholder='Enter up to 5 categories' value='' multiple='multiple'></select>" +
        "</li>"
      $('#xbrsHistorySelectedUrlsList').append(selectize_url_li)
      $("#xbrs-history-#{name}").selectize {
        create: false,
        labelField: 'category_name',
        maxItems: 5,
        onInitialize: () ->
          domain = this.$input.parent().data().url
          selectize = this

          $.ajax(
            url: '/escalations/api/v1/escalations/webcat/complaints/lookup_prefix'
            headers: headers
            method: 'POST'
            data: { 'urls': [domain] }
            success: (response) ->
              data = response.json
              for domainKey in Object.keys(data)
                for category_key in Object.keys(data[domainKey])
                  category_id = data[domainKey][category_key]
                  if Object.keys(selectize.getOption(category_id)).length < 1
                    categoryOption = categoryList.filter (cat) -> cat.category_id is category_id
                    selectize.addOption(categoryOption)

                  selectize.addItem(category_id)
            error: (errorResponse) ->
              std_api_error(errorResponse, "Category info for #{domain} could not be retrieved.", reload: false)
          )
        options: AC.WebCat.createSelectOptions("#xbrs-history-#{name}"),
        persist: true,
        score: (input) ->
          #  Adding some customization for autofill
          #  restricting on certain cats to avoid accidental categorization
          #  (replaces selectize's built-in `getScoreFunction()` with our own)
          (item) ->
            if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
              item.category_code == input ? 1 : 0
            else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
              1
            else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
              0.9
            else
              0
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }

      setXbrsSelectLimiter(1)
      $('#xbrs-history-webcat-research-categorize-url').removeAttr('disabled')
      $("#xbrs-history-limit-warning").hide()
    else if !button.is(':checked') && ($("#xbrsHistorySelectedUrlsList > li[data-name='#{name}']").length isnt 0) && $(".xbrs-categorize-url-button:checked[data-name='#{name}']").length is 0
      $("#xbrsHistorySelectedUrlsList > li[data-name='#{name}']").remove()
      setXbrsSelectLimiter(-1)
      $("#xbrs-history-limit-warning").hide()
    else if button.is(':checked') && xbrsSelectLimiter is 10
      $("#xbrs-history-limit-warning").show()

    $categorizeButton = $('#xbrs-history-webcat-research-categorize-url')

    if (xbrsSelectLimiter is 0) && !$categorizeButton.attr('disabled')?
      $categorizeButton.attr('disabled', 'disabled')
    else if (xbrsSelectLimiter isnt 0) && $categorizeButton.attr('disabled')?
      $categorizeButton.removeAttr('disabled')

    if $('#xbrsHistorySelectedUrlsList').find('li').length is 0
      $('#xbrsHistoryCheckAll').prop('checked', false)
  )

  $(document).on("click", '.domain-history-categorize-url-button', () ->
    button = $(this)
    data = button.data()

    name = data.name.replace(/\<|\>|\(|\)/g, '')
    url = data.url.replace(/\<|\>|\(|\)/g, '')

    if button.is(':checked') && domainHistorySelectLimiter < 10 && ($("#domainHistorySelectedUrlsList > li[data-name='#{name}'").length is 0)
      selectize_url_li =
        "<li data-name='#{name}' data-url='#{url}'>#{url}" +
          "<select id='domain-history-#{name}' class='form-control selectize' placeholder='Enter up to 5 categories' value='' multiple='multiple'></select>" +
          "</li>"
      $('#domainHistoryTableSelectedUrlsList').append(selectize_url_li)
      $("#domain-history-#{name}").selectize {
        create: false,
        labelField: 'category_name',
        maxItems: 5,
        onInitialize: () ->
          domain = this.$input.parent().data().url
          selectize = this

          $.ajax(
            url: '/escalations/api/v1/escalations/webcat/complaints/lookup_prefix'
            headers: headers
            method: 'POST'
            data: { 'urls': [domain] }
            success: (response) ->
              data = response.json
              for domainKey in Object.keys(data)
                for category_key in Object.keys(data[domainKey])
                  category_id = data[domainKey][category_key]
                  if Object.keys(selectize.getOption(category_id)).length < 1
                    categoryOption = categoryList.filter (cat) -> cat.category_id is category_id
                    selectize.addOption(categoryOption)

                  selectize.addItem(category_id)
            error: (errorResponse) ->
              std_api_error(errorResponse, "Category info for #{domain} could not be retrieved.", reload: false)
          )
        options: AC.WebCat.createSelectOptions("#domain-history-#{name}"),
        persist: true,
        score: (input) ->
          #  Adding some customization for autofill
          #  restricting on certain cats to avoid accidental categorization
          #  (replaces selectize's built-in `getScoreFunction()` with our own)
          (item) ->
            if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
              item.category_code == input ? 1 : 0
            else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
              1
            else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
              0.9
            else
              0
        searchField: ['category_name', 'category_code'],
        valueField: 'category_id'
      }

      domainHistorySelectLimiter += 1
      $("#domain-history-limit-warning").hide()
    else if !button.is(':checked') && ($("#domainHistoryTableSelectedUrlsList > li[data-name='#{name}']").length isnt 0) && $(".domain-history-categorize-url-button:checked[data-name='#{name}']").length is 0
      $("#domainHistoryTableSelectedUrlsList > li[data-name='#{name}']").remove()
      domainHistorySelectLimiter -= 1
      $("#domain-history-limit-warning").hide()
    else if button.is(':checked') && domainHistorySelectLimiter is 10
      $("#domain-history-limit-warning").show()

    $categorizeButton = $('#domain-history-webcat-research-categorize-url')

    if (domainHistorySelectLimiter is 0) && !$categorizeButton.attr('disabled')?
      $categorizeButton.attr('disabled', 'disabled')
    else if (domainHistorySelectLimiter isnt 0) && $categorizeButton.attr('disabled')?
      $categorizeButton.removeAttr('disabled')

    if $('#domainHistorySelectedUrlsList').find('li').length is 0
      $('#domainHistoryCheckAll').prop('checked', false)
  )

  checkAll = (headerCheckBox, tableId) ->
    checkAllValue = $(headerCheckBox).is(':checked')
    tableCheckBoxes = $(tableId).find('.categorize-url-button')
    urlList

    if tableId.indexOf('domainHistory') != -1
      urlList = $('#domainHistoryTableSelectedUrlsList')
      tableClassPrepend = 'domain-history'
      selectLimiter = getDhSelectLimiter
      setSelectLimiter = setDhSelectLimiter
    else
      urlList = $('#xbrsHistorySelectedUrlsList')
      tableClassPrepend = 'xbrs-history'
      selectLimiter = getXbrsSelectLimiter
      setSelectLimiter = setXbrsSelectLimiter

    for checkBox in tableCheckBoxes
      $checkBox = $(checkBox)
      data = $checkBox.data()

      name = data.name.replace(/\<|\>|\(|\)/g, '')
      url = data.url.replace(/\<|\>|\(|\)/g, '')

      $checkBox.prop('checked', checkAllValue)

      if checkAllValue && (urlList.find("li[data-name='#{name}']").length is 0) && (selectLimiter() < 10)
        # Row will change to the value of the last item in the loop so we have to capture the id.
        selectId = "#{tableClassPrepend}-#{name}"
        selectize_url_li =
          "<li data-name='#{name}' data-url='#{url}'>#{url}" +
            "<select id='#{selectId}' class='form-control selectize' placeholder='Enter up to 5 categories' value='' multiple='multiple'></select>" +
            "</li>"
        urlList.append(selectize_url_li)
        $("##{tableClassPrepend}-#{name}").selectize {
          create: false,
          labelField: 'category_name',
          maxItems: 5,
          onInitialize: () ->
            domain = this.$input.parent().data().url
            selectize = this

            $.ajax(
              url: '/escalations/api/v1/escalations/webcat/complaints/lookup_prefix'
              headers: headers
              method: 'POST'
              data: { 'urls': [domain] }
              success: (response) ->
                data = response.json
                for domainKey in Object.keys(data)
                  for category_key in Object.keys(data[domainKey])
                    category_id = data[domainKey][category_key]
                    if Object.keys(selectize.getOption(category_id)).length < 1
                      categoryOption = categoryList.filter (cat) -> cat.category_id is category_id
                      selectize.addOption(categoryOption)

                    selectize.addItem(category_id)
              error: (errorResponse) ->
                std_api_error(errorResponse, "Category info for #{domain} could not be retrieved.", reload: false)
            )

          options: AC.WebCat.createSelectOptions("##{selectId}"),
          persist: true,
          score: (input) ->
            #  Adding some customization for autofill
            #  restricting on certain cats to avoid accidental categorization
            #  (replaces selectize's built-in `getScoreFunction()` with our own)
            (item) ->
              if item.category_code == 'cprn' || item.category_code == 'xpol' || item.category_code == 'xita' || item.category_code == 'xgbr' || item.category_code == 'xdeu' || item.category_code == 'piah'
                item.category_code == input ? 1 : 0
              else if item.category_name.toLowerCase().startsWith(input.toLowerCase())
                1
              else if item.category_name.toLowerCase().includes(input.toLowerCase()) || item.category_code.toLowerCase().includes(input.toLowerCase())
                0.9
              else
                0
          searchField: ['category_name', 'category_code'],
          valueField: 'category_id'
        }

        setSelectLimiter(1)
        $("##{tableClassPrepend}-limit-warning").hide()
      else if !checkAllValue && (urlList.find("li[data-name='#{name}']").length isnt 0)
        urlList.find("li[data-name='#{name}']").remove()
        setSelectLimiter(-1)
        $("input[data-name='#{name}'").prop('checked', checkAllValue)
        $("##{tableClassPrepend}-limit-warning").hide()
      else if checkAllValue && (selectLimiter() is 10)
        $("##{tableClassPrepend}-limit-warning").show()

    $categorizeButton = $("##{tableClassPrepend}-webcat-research-categorize-url")

    if (selectLimiter() is 0) && !$categorizeButton.attr('disabled')?
      $categorizeButton.attr('disabled', 'disabled')
    else if (selectLimiter() isnt 0) && $categorizeButton.attr('disabled')?
      $categorizeButton.removeAttr('disabled')

  $('#domainHistoryCheckAll').click(() ->
    checkAll(this, '#domainHistoryTableBody')
  )

  $('#xbrsHistoryCheckAll').click(() ->
    checkAll(this, '#xbrsHistoryTableBody')
  )

  window.apply_webcat_research_categories = (tab) ->
    listId = if tab == 'xbrs' then '#xbrsHistorySelectedUrlsList' else "#domainHistoryTableSelectedUrlsList"
    entries = []
    successfulCalls = []
    failedCalls = []
    erroredCalls = []
    callsToMake = 0
    callsCompleted = 0
    urlListItems = $(listId).find('li')
    self_review = $('#self_review').is(':checked')

    for listItem in urlListItems
      entries.push $(listItem).data().url

    entries = $.unique(entries)
    callsToMake = entries.length

    if tab == 'xbrs'
      $("#xbrs-history-webcat-research-categorize-url").dropdown('toggle')
      $("#xbrsHistoryLoader").toggle()
    else
      $("#domain-history-webcat-research-categorize-url").dropdown('toggle')
      $("#domainHistoryLoader").toggle()

    for entry, index in entries
      category_ids = []
      categories = []
      urlsListItems = $(listId).find('li')
      selectize = $($(urlsListItems)[index]).find('select')[0].selectize

      for item in selectize.items
        category_ids.push item

        categories.push selectize.getItem(item)[0].innerText

      $.ajax(
        url: '/escalations/api/v1/escalations/webcat/complaints/bulk_categorize'
        method: 'POST'
        headers: headers
        data:
          'entries': [entry],
          'category_ids': category_ids,
          'categories': categories,
          'self_review': self_review
        success: (response) ->
          data = response.data
          callsCompleted += 1
          unless data.complete_failed.length > 0 || data.create_failed.length > 0
            successfulCalls.push data.completed[0]
          else
            failedCalls.push data.complete_failed[0] || data.create_failed[0]
        error: (response) ->
          callsCompleted += 1
          erroredCalls.push response.responseText
        complete: (response) ->
          if callsToMake == callsCompleted
            if tab == 'xbrs'
              $("#xbrsHistoryLoader").toggle()
            else
              $("#domainHistoryLoader").toggle()

            if erroredCalls.length > 0
              erroredCalls.unshift 'Tickets were not created for the following items.'
              std_msg_error('Categories were not assigned.', erroredCalls, reload: false)
            else if failedCalls.length > 0
              failedCalls.unshift 'Tickets were not created for the following items.'
              std_msg_error('Categories were not assigned.', failedCalls, reload: false)
            else
              entries.unshift 'Tickets have been created for the following items:'
              std_msg_success(
                'URLs categorized successfully',
                entries,
                reload: false)
        , this)
