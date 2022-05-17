headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}


window.get_sdr_research_data = (entry) ->
  $.ajax(
    url: '/escalations/api/v1/escalations/cloud_intel/tea/get_data'
    method: 'POST'
    headers: headers
    data: {entry: entry}
    success: (response) ->
      data = response.data
      fill_out_sdr_research_data(data)
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-present').show()
      beautify_beaker()

    error: (error) ->
      std_msg_error(error.responseText, ['Unable to fetch SDR data.'])
      $('#sdr-research-loader').hide()
      $('.sdr-research-data-missing').show()
  )

  fill_out_sdr_research_data = (data) ->
    # Keep console log for now to test out TEA data that gets returned
    console.log data

    for key of data
      # breaking these apart so we can easily see and customize
      # which pieces of data we are showing / how they are shown
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
      if ($(this).text() == '') || ($(this).text() == 'null' || $(this).text() == 'undefined' || $(this).text() == 'NaN')
        $(this).html('<span class="missing-data">N/A</span>')


  $('#sdr-research-tab .expand-row-button-inline').click ->
    expandButton = $(this)
    nestedRow = expandButton.siblings('.nested-data-row')[0]
    $(nestedRow).toggle()



window.beautify_beaker = () ->
  # Beautify poorly formatted json dump
  $('.beaker-json-dump').each ->
    beaker_txt = $(this).text()
    return if beaker_txt is ''
    bkr_Obj = JSON.parse(beaker_txt)
    beaker_pretty = JSON.stringify(bkr_Obj, null, 2);

    $(this).text(beaker_pretty)

window.beautify_email_headers = () ->
  # Format the email attachment headers for legibility
  $('.email-json-dump').each ->
    txt_wrapper = this
    headerstxt = $(txt_wrapper).text()
    return if headerstxt is ''
    headerObj = JSON.parse(headerstxt)
    tbl = '<table class="email-headers-table">'

    for key of headerObj
      value = headerObj[key]
      row = "<tr><th>" + key + "</th><td>" + value + "</td></tr>"
      tbl = tbl + row

    tbl = tbl + "</table>"
    $(txt_wrapper).html(tbl)

window.beautify_details_field = () ->
  raw_txt = $('.sdr-details').text()
  formatted_details = raw_txt.replace(/\\r\\n|\n|\r|\r\n|\\r|\\n/g, '<br/>')
  $('.sdr-details').html(formatted_details)

window.open_corpus_dialog = () ->
  dialog = $('#send-to-corpus-wrapper')

  #check which attachments are checked
  #build table
  dialog.dialog('open')

window.enable_send_to_corpus = () ->
  submit = $('#submitCorpus')
  enable = true
  $('.corpus-row').each (index)->
    unless $("input[name='category#{index}']:checked").val()
      enable = false

  if enable == true
    $(submit).removeAttr('disabled')
  else
    $(submit).attr('disabled', 'disabled')


$ ->
  beautify_email_headers()
  beautify_details_field()

  $('#submitCorpus').click () ->
    failedCalls = 0
    $('.corpus-row').each (index)->
      row = $(this)
      attachmentId = parseInt(row.find('input[name="attachmentId"]').val(), 10)
      category = $("input[name='category#{index}']:checked").val()
      subject = row.find('input[name="subject line"]').val()
      tags = (tag.name for tag in row.find('input[type="checkbox"]:checked'))
      tags = tags.join(', ')

      $.ajax(
        url: '/escalations/api/v1/escalations/sdr/disputes/submit_to_corpus'
        method: 'POST'
        headers: headers
        data: {id: attachmentId, subject: subject, tag: tags, email: category }
        success: (response) ->
          console.log 'response', response
        error: (error) ->
          failedCalls++
          std_msg_error(error.responseText, ['Unable to attachment data to corpus.'])
      )
      unless failedCalls > 0
        std_msg_success('Attachments sent to Corpus', [], { reload: false })
        $('.sdr-corpus-button').dropdown('toggle')

  # Initialize send to corpus dialog
  $('#send-to-corpus-wrapper').dialog({autoOpen : false, width: 1000});

  # Check / enable button (make sure each attachment has a category selected)
  $('.email-category').on 'change', ->
    enable_send_to_corpus()
