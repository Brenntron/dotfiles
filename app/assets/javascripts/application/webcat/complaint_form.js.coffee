complaint_status_list= ["NEW", "RESOLVED", "ASSIGNED", "ACTIVE","COMPLETED","PENDING"]
complaint_channel_list=["Internal", "TalosIntel", "WBNP"]
complaint_resolution_list=["RESOLUTION_FIXED", "RESOLUTION_INVALID", "RESOLUTION_UNCHANGED", "RESOLUTION_DUPLICATE"]
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
        i = 0
        while i < response.data.length
          $('#customerList').append '<option value=\'' + response.data[i] + '\'></option>'
          i++
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

        i = 0
        while i < response.data.length
          if uniques.indexOf(response.data[i]) == -1
            uniques.push(response.data[i])
          i++

        j = 0
        while j < uniques.length
          $('#customerList').append '<option value=\'' + uniques[j] + '\'></option>'
          j++

        for status in complaint_status_list
          $('#status-input-list').append '<option value=\'' + status + '\'></option>'

        for channel in complaint_channel_list
          console.log(channel)
          $('#channel-input-list').append '<option value=\'' + channel + '\'></option>'

        for resolution in complaint_resolution_list
          console.log(resolution, $('#resolution-input'))
          $('#resolution-input-list').append '<option value=\'' + resolution + '\'></option>'

    )

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/customers_company_name'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerCompanyList').empty()

        uniques = []

        i = 0
        while i < response.data.length
          if uniques.indexOf(response.data[i]) == -1
            uniques.push(response.data[i])
          i++

        j = 0
        while j < uniques.length
          $('#customerCompanyList').append '<option value=\'' + uniques[j] + '\'></option>'
          j++
    )

    $.ajax(
      url: '/escalations/api/v1/escalations/webcat/customers_email'
      method: 'GET'
      dataType: 'json'
      headers: headers
      success: (response) ->
        $('#customerEmailList').empty()

        uniques = []

        i = 0
        while i < response.data.length
          if uniques.indexOf(response.data[i]) == -1
            uniques.push(response.data[i])
          i++

        j = 0
        while j < uniques.length
          $('#customerEmailList').append '<option value=\'' + uniques[j] + '\'></option>'
          j++

    )

    $('')

  $('#new-complaint-form').submit (e) ->
    e.preventDefault()
    $('#loader-modal').modal({
      backdrop: 'static',
      keyboard: false
    })
    ips_urls = this.ips_urls.value
    desc = this.description.value
    customer = this.customers.value
    tags = $('.selectize').val() || []

    std_msg_ajax(
      url: '/escalations/api/v1/escalations/webcat/complaints'
      method: 'POST'
      data:
        ips_urls: ips_urls,
        description: desc,
        customer: customer,
        tags: tags
      success: (response) ->
        $('#loader-modal').modal 'hide'
        std_msg_success('Complaint Created.', [], reload: true)
      error: (response) ->
        $('#loader-modal').modal 'hide'
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
