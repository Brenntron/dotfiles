complaint_status_list= ["NEW", "RESOLVED", "ASSIGNED", "ACTIVE","COMPLETED", "PENDING", "REOPENED" ]
complaint_channel_list=["Internal", "TalosIntel", "WBNP"]
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

  $('#advanced-search-button').on 'click', ->

    headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
    $.ajax(
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

        for channel in complaint_channel_list
          $('#channel-input-list').append '<option value="' + channel + '"></option>'

        for resolution in complaint_resolution_list
          $('#resolution-input-list').append '<option value="' + resolution + '"></option>'

    )

    $.ajax(
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

    $.ajax(
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
    ips_urls = this.ips_urls.value
    desc = this.description.value
    customer = this.customers.value
    tags = $('.selectize').val() || []
    $('#new-complaint').dropdown('toggle');
    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints'
      method: 'POST'
      data:
        ips_urls: ips_urls,
        description: desc,
        customer: customer,
        tags: tags
      success: (response) ->
        std_msg_success('Complaint Created.', [], reload: true)
      error: (response) ->
        std_api_error(response, "Complaint was not created.", reload: false)
    )

  $('#cancel_complaint').on 'click', ->
    $(':input','#new-complaint-form').val('')
    $('#new-complaint').dropdown('toggle')


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

  }
