complaint_status_list= ["NEW", "RESOLVED", "ASSIGNED", "ACTIVE","COMPLETED", "PENDING", "REOPENED" ]
complaint_resolution_list=["FIXED", "INVALID", "UNCHANGED", "DUPLICATE"]
$ ->

  $('#new-complaint').on 'click', ->
    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/customers'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerList').empty()
        for data, i in response.data
          $('#customerList').append '<option value="' + data + '"></option>'
    )

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/platforms_names'
      method: 'GET'
      success: (response) ->
        $('#platformList').empty()
        for platform in response.data
          $('#platformList').append '<option value="' + platform + '"></option>'
    )


  $('#advanced-search-button').on 'click', ->
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/customers_names'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#channel-input-list').empty()
        $('#status-input-list').empty()
        $('#resolution-input-list').empty()
        $('#customerList').empty()

        uniques = []

        for data, i in response.data
          if uniques.indexOf(i) == -1
            uniques.push(data)

        for customer in uniques
          $('#customerList').append '<option value="' + customer + '"></option>'

        for status in complaint_status_list
          $('#status-input-list').append '<option value="' + status + '"></option>'

        for resolution in complaint_resolution_list
          $('#resolution-input-list').append '<option value="' + resolution + '"></option>'

        if window.location.pathname.includes('webcat')
          AC.WebCat.createCompanyOptions()
          AC.WebCat.createCustomerNameOptions()
          AC.WebCat.createAssigneeOptions()
          AC.WebCat.populateSearchCriteria()

        if window.location.pathname.includes('file_rep')
          AC.FileRep.createAssigneeOptions()
          AC.FileRep.populateSearchCriteria()
          AC.FileRep.createPlatformOptions()
    )


    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/customers_company_name'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerCompanyList').empty()

        uniques = []

        for data, i in response.data
          if uniques.indexOf(i) == -1
            uniques.push(data)

        for company in uniques
          $('#customerCompanyList').append '<option value="' + company + '"></option>'
    )

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/customers_email'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerEmailList').empty()
        uniques = []
        for data, i in response.data
          if uniques.indexOf(i) == -1
            uniques.push(data)
        for email in uniques
          $('#customerEmailList').append '<option value="' + email + '"></option>'
    )

  $('#new-complaint-form').submit (e) ->
    e.preventDefault()
    unparsed_ips_urls = this.ips_urls.value.replace(/, |,|\n/g,' ').split(' ')
    for ip_url, i in unparsed_ips_urls
      if !/^[0-9,.]*$/.test(ip_url)
        http = ""
        if !ip_url.includes('http://')
          http = 'http://'
        url = new URL(http + ip_url.trim())
        url.host = url.host.toLowerCase()
        new_url = url.toString().replace('http://', http)
        if http = 'http://'
          new_url = new_url.replace('http://', '')
        if url.pathname == '/'
          new_url = new_url.substring(0, new_url.length - 1);
        unparsed_ips_urls[i] = new_url

    ips_urls = unparsed_ips_urls.join(' ')
    desc = this.description.value
    customer = this.customers.value
    platform = this.platforms.value
    tags = $('.selectize').val() || []
    $('#new-complaint').dropdown('toggle');


    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints'
      method: 'POST'
      data:
        ips_urls: ips_urls,
        description: desc,
        customer: customer,
        platform: platform,
        tags: tags
      success: (response) ->
        parsed = JSON.parse(response)

        if parsed.status == "error"
          if parsed.successful_entries_count > 0
            message = "Not all complaints were able to be created"
            fail_msg = "The following #{parsed.failed_entries_count} complaints were not able to be created"
            success_msg = "The following #{parsed.successful_entries_count} complaints were successfully created"
            parsed.failed_entries.unshift(fail_msg)
            parsed.successful_entries.unshift(success_msg)
            merged_entry_msg = parsed.failed_entries.concat(parsed.successful_entries)
            std_msg_error(message, merged_entry_msg, reload: true)
          else
            message = "The following #{parsed.failed_entries_count} complaints were not able to be created"
            std_msg_error(message, parsed.failed_entries, reload: false)

        else if parsed.status == 'success'
          message = "The following #{parsed.successful_entries_count} complaints were successfully created"
          std_msg_success(message, parsed.successful_entries, reload: true)

      error: (response) ->
        console.log response
        std_api_error(response, "Complaints were not created.", reload: false)
    )

  $('#cancel_complaint').on 'click', ->
    $(':input','#new-complaint-form').val('')
    $('#new-complaint').dropdown('toggle')
    $('#select-to-new').selectize()[0].selectize.clear()


  createSelectOptions = ->
    tags = $('#complaint_tag_list')[0]
    if tags
      tag_list = tags.value
      array = tag_list.split(',')
      options = []
      for x in array
        options.push {name: x}
      return options

  $('#select-to-new').selectize {
    persist: false,
    create: (input) ->
      {name: input}
    maxItmes: null
    valueField: 'name'
    labelField: 'name'
    searchField: 'name'
    options: createSelectOptions()
    onFocus: () ->
      window.toggle_selectize_layer(this, 'true')
    onBlur: () ->
      window.toggle_selectize_layer(this, 'false')

  }
