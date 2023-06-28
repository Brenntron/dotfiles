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

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
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

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
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

        { webcat_search_conditions, webcat_search_type } = localStorage

        if webcat_search_type?
          if webcat_search_type == 'advanced'
            { user_id } = JSON.parse localStorage.webcat_search_conditions

            if user_id
              element[0].selectize.setValue(user_id)
    )

  exports.populateSearchCriteria = ->
    return unless localStorage.webcat_search_conditions
    searchConditions = JSON.parse localStorage.webcat_search_conditions
    for label, searchCriteria of searchConditions
      continue if searchCriteria == ''

      selectize_elements = ['entryid','complaint_id','jira_id']

      if label == 'id' then label = 'entryid'
      if label == 'platform_ids' then label = 'platform'
      if label == 'ip_or_uri' then label = 'complaint'
      if label == 'customer_email' then label = 'email'

      searchlabel = label.replace('_',  '').replace('ids',  '')
      input_element = $("##{searchlabel}-input")

      if selectize_elements.includes(label)
        values = searchCriteria.split(', ')
        for val in values
          input_element[0].selectize.addOption({ value: val, text: val })

      if searchLabel == 'id' || searchLabel == 'ip_or_uri' || searchLabel == 'complaint_id' || searchLabel == 'jira_id'
        splitSearchCriteria = searchCriteria.split(', ')
        $searchLabel[0].selectize.setValue(splitSearchCriteria)
      else if $searchLabel[0] && $searchLabel[0].selectize
        $searchLabel[0].selectize.setValue(searchCriteria)
      else
        $searchLabel.val(searchCriteria)

#      switch searchlabel
#        when 'ip_or_uri'
#          input_element[0].selectize.addOption({ value: searchCriteria, text: searchCriteria })
#          complaints = searchCriteria.split(', ')
#          for complaint in complaints
#            input_element[0].selectize.addOption({ value: complaint, text: complaint })
#      else if searchLabel == 'id'
#        $searchLabel = $('#entryid-input')
#        entryids = searchCriteria.split(', ')
#        for entryid in entryids
#          $searchLabel[0].selectize.addOption({ value: entryid, text: entryid })
#      else if searchLabel == 'customer_email'
#        $searchLabel = $('#email-input')
#      else if searchLabel == 'complaint_id'
#        $searchLabel = $('#complaintid-input')
#        complaintIds = searchCriteria.split(', ')
#        for complaintId in complaintIds
#          $searchLabel[0].selectize.addOption({ value: complaintId, text: complaintId })
#      else if searchLabel == 'jira_id'
#        $searchLabel = $('#jiraid-input')
#        jiraIds = searchCriteria.split(', ')
#        for id in jiraIds
#          $searchLabel[0].selectize.addOption({ value: id, text: id })
#      else
#        searchLabelTransformed = searchLabel.replace /_ids/, ''
#        searchLabelTransformed = searchLabelTransformed.replace /_/, '-'
#        $searchLabel = $("##{searchLabelTransformed}-input")
#
#      if searchLabel == 'id' || searchLabel == 'ip_or_uri' || searchLabel == 'complaint_id' || searchLabel == 'jira_id'
#        splitSearchCriteria = searchCriteria.split(', ')
#        $searchLabel[0].selectize.setValue(splitSearchCriteria)
#      else if $searchLabel[0] && $searchLabel[0].selectize
#        $searchLabel[0].selectize.setValue(searchCriteria)
#      else
#        $searchLabel.val(searchCriteria)

      $("##{searchLabel}-input").removeClass('hidden')
