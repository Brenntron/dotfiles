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

        { user_id } = JSON.parse localStorage.webcat_search_conditions

        if user_id
          element[0].selectize.setValue(user_id)
    )

  exports.populateSearchCriteria = ->
    searchConditions = JSON.parse localStorage.webcat_search_conditions
    console.log searchConditions
    for searchLabel, searchCriteria of searchConditions
      break if searchCriteria == ''

      if searchLabel == 'platform_ids'
        $searchLabel = $('#platform-input')
      else
        searchLabelTransformed = searchLabel.replace /_ids/, ''
        searchLabelTransformed = searchLabelTransformed.replace /_/, '-'
        $searchLabel = $("##{searchLabelTransformed}-input")

      if $searchLabel[0] && $searchLabel[0].selectize
        $searchLabel[0].selectize.setValue(searchCriteria)
      else
        $searchLabel.val(searchCriteria)

      $("##{searchLabel}-input").removeClass('hidden')
