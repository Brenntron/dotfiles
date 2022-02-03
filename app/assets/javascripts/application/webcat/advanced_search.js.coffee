namespace 'AC.WebCat', (exports) ->

  exports.createCompanyOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/companies"
      success_reload: false
      success: (response) ->
        element = $('#company-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for company in json
          selectize.addOption(company)

        webcat_search_conditions = localStorage.webcat_search_conditions

        if webcat_search_conditions && JSON.parse(localStorage.webcat_search_conditions).company_name
          { company_name } = JSON.parse localStorage.webcat_search_conditions

          if company_name
            element[0].selectize.setValue(company_name)
    )

  exports.createCustomerNameOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/escalations/webcat/customers_names_selectize"
      success_reload: false
      success: (response) ->
        element = $('#name-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for customer_name in json
          selectize.addOption(customer_name)

        webcat_search_conditions = localStorage.webcat_search_conditions

        if webcat_search_conditions && JSON.parse(localStorage.webcat_search_conditions).customer_name
          { customer_name } = JSON.parse localStorage.webcat_search_conditions

          if customer_name
            element[0].selectize.setValue(customer_name)
    )

  exports.createAssigneeOptions = ->
    std_msg_ajax(
      method: 'GET'
      url: "/escalations/api/v1/users/json"
      success_reload: false
      success: (response) ->
        element = $('#assignee-input')
        selectize = element[0].selectize

        json = JSON.parse(response)

        for assignee in json
          selectize.addOption(assignee)

        webcat_search_conditions = localStorage.webcat_search_conditions

        if webcat_search_conditions && JSON.parse(webcat_search_conditions).user_id
          { user_id } = JSON.parse localStorage.webcat_search_conditions

          if user_id
            element[0].selectize.setValue(user_id)
    )

  exports.populateSearchCriteria = ->
    return unless localStorage.webcat_search_conditions
    searchConditions = JSON.parse localStorage.webcat_search_conditions
    for searchLabel, searchCriteria of searchConditions
      continue if searchCriteria == ''

      if searchLabel == 'platform_ids'
        $searchLabel = $('#platform-input')
      else if searchLabel == 'ip_or_uri'
        $searchLabel = $('#complaint-input')
        $searchLabel[0].selectize.addOption({ value: searchCriteria, text: searchCriteria })
      else if searchLabel == 'id'
        $searchLabel = $('#entryid-input')
        $searchLabel[0].selectize.addOption({ value: searchCriteria, text: searchCriteria })
      else if searchLabel == 'customer_email'
        $searchLabel = $('#email-input')
      else
        searchLabelTransformed = searchLabel.replace /_ids/, ''
        searchLabelTransformed = searchLabelTransformed.replace /_/, '-'
        $searchLabel = $("##{searchLabelTransformed}-input")

      if $searchLabel[0] && $searchLabel[0].selectize
        $searchLabel[0].selectize.setValue(searchCriteria)
      else
        $searchLabel.val(searchCriteria)

      $("##{searchLabel}-input").removeClass('hidden')
