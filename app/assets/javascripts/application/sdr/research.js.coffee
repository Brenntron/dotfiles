headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


window.get_sdr_research_data = (entry) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/tea/get_data'
    method: 'POST'
    headers: headers
    data: {entry: entry}
    success: (response) ->
      data = response.data
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-present').show()
      fill_out_sdr_research_data(data)


    error: (error) ->
      std_msg_error(error.responseText, ['Unable to fetch SDR data.'])
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-missing').show()
  )

  fill_out_sdr_research_data = (data) ->
    # Keep console log for now to test out TEA data that gets returned
    console.log data

    for key of data
      if data.hasOwnProperty(key)
        value = data[key]
        if key == 'entry'
          table_content =
            '<tr>' +
              '<td>' + value.url + '</td>' +
              '<td>' + value.ip_address + '</td>' +
            '</tr>'
          $('#sdr-reputation-data-table tbody').append(table_content)

        else if key == 'web_reputation'
          table_content =
            '<td>' + value.score + '</td>' +
            '<td>' + value.rules + '</td>' +
            '<td>' + value.threat_level + '</td>' +
            '<td>' + value.category + '</td>'
          $('#sdr-reputation-data-table tbody tr').append(table_content)

        else if key == 'security_intelligence'
          table_content =
            '<tr>' +
              '<td>' + value.bl_classification + '</td>' +
              '<td>' + value.bl_comment + '</td>' +
              '<td>' + value.bl_status + '</td>' +
              '<td>' + value.wl_status + '</td>' +
            '</tr>'
          $('#sdr-security-data-table tbody').append(table_content)

        else if key == 'virustotal'
          table_content =
            '<tr>' +
              '<td>' + value.url_detection + '</td>' +
              '<td>' + value.trusted_detection + '</td>' +
              '<td>' + value.detected_urls + '</td>' +
              '</tr>'
          $('#sdr-vt-data-table tbody').append(table_content)

        else if key == 'umbrella'
          popularity = parseFloat(value.popularity).toFixed(2)

          table_content =
            '<tr>' +
              '<td class="text-capitalize">' + value.rating + '</td>' +
              '<td>' + value.category + '</td>' +
              '<td>' + popularity + '</td>' +
              '<td>' + value.domain_volume + '</td>' +
              '<td>' + value.organization + '</td>' +
              '<td>' + value.registrar + '</td>' +
              '<td>' + value.created + '</td>' +
              '</tr>'
          $('#sdr-umbrella-data-table tbody').append(table_content)

    # address missing or null vals
    $('.sdr-research-data-wrapper .data-report-table tbody tr td').each ->
      if ($(this).text() == '') || ($(this).text() == 'null')
        $(this).html('<span class="missing-data">Not available</span>')



  $('#sdr-research-tab .expand-row-button-inline').click ->
    expandButton = $(this)
    nestedRow = expandButton.siblings('.nested-data-row')[0]
    $(nestedRow).toggle()
