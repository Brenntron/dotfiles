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
    bkr_Obj = JSON.parse(beaker_txt)
    beaker_pretty = JSON.stringify(bkr_Obj, null, 2);

    $(this).text(beaker_pretty)

window.beautify_email_headers = () ->
  # Format the email attachment headers for legibility
  $('.email-json-dump').each ->
    txt_wrapper = this
    headerstxt = $(txt_wrapper).text()
    headerObj = JSON.parse(headerstxt)

    # pull subject & add to attachment cb
    subject = headerObj['Subject']
    checkbox = $(this).parents('.attachment-data-wrapper').find('.corpus-attachment')
    $(checkbox).attr('data-subject', subject)

    # parse out email headers
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
  att_table = $(dialog).find('.attachment-to-send-table tbody')
  submit_btn = $('#submitCorpus')

  # dialog reset
  $(dialog).find('.dialog-close').addClass('hidden')
  $(submit_btn).show()
  $(submit_btn).attr('disabled', 'disabled')
  $(att_table).empty()

  if $('.corpus-attachment:checked').length > 0

    #check which attachments are checked
    $('.corpus-attachment:checked').each () ->
      # grab attachment id, filename, and subject
      id = $(this).attr('data-id')
      filename = $(this).attr('data-filename')
      subject = $(this).attr('data-subject')

      # build table
      table_row =
        '<tr class="submit-attachment-row" data-id="' + id + '">' +
        '<td>' + filename + '</td>' +
        '<td class="alt-col input-col text-center">' +
          '<input class="email-category" type="radio" value="spam" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="email-category" type="radio" value="phish" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="alt-col input-col text-center">' +
          '<input class="email-category" type="radio" value="virus" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="email-category" type="radio" value="ham" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="alt-col input-col text-center">' +
          '<input class="email-category" type="radio" value="ads" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="email-category" type="radio" value="not ads" name="email-category-' + id + '">' +
        '</td>' +
        '<td class="alt-col input-col">' +
          '<input class="attachment-subject" type="text" name="subject-' + id + '" value="' + subject + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="attachment-tag" type="checkbox" value="[SUSPECTED SPAM]" name="tag-spam-' + id + '">' +
        '</td>' +
        '<td class="alt-col input-col text-center">' +
          '<input class="attachment-tag" type="checkbox" value="[MARKETING]" name="tag-marketing-' + id + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="attachment-tag" type="checkbox" value="[SOCIAL NETWORK]" name="tag-social-network-' + id + '">' +
        '</td>' +
        '<td class="alt-col input-col text-center">' +
          '<input class="attachment-tag" type="checkbox" value="[BULK]" name="tag-bulk-' + id + '">' +
        '</td>' +
        '<td class="input-col text-center">' +
          '<input class="attachment-tag" type="checkbox" value="[WARNING: VIRUS DETECTED]" name="tag-virus-' + id + '">' +
        '</td>' +
        '</tr>'
      $(att_table).append(table_row)

    dialog.dialog('open')


window.enable_send_to_corpus = () ->
  submit = $('#submitCorpus')
  enable = true

  $('.submit-attachment-row').each ()->
    unless $(this).find(".email-category:checked").val()
      enable = false

  if enable == true
    $(submit).removeAttr('disabled')
  else
    $(submit).attr('disabled', 'disabled')


window.prep_submit_to_corpus = () ->
  dialog = $('#send-to-corpus-wrapper')
  close_btn = $(dialog).find('.dialog-close')

  # remove ability to hit submit again after initial submit
  $('#submitCorpus').hide()
  $(close_btn).removeClass('hidden')
  $(close_btn).on 'click', ->
    $(dialog).dialog('close')

  $(dialog).find('.submit-attachment-row').each ->
    attachment_id = $(this).attr('data-id')
    email_category = $(this).find('.email-category:checked').val()
    subject = $(this).find('.attachment-subject').val()
    tag = $(this).find('.attachment-tag:checked')

    tags = []
    $(tag).each ->
      val = $(this).val()
      tags.push(val)
    tags = tags.join(', ')

    data = {
      id: attachment_id, subject: subject, tag: tags, email: email_category
    }

    # show a loader while the file is being submitted
    loader = '<span class="inline-row-loader"><span class="sync-button sync_rotate"></span>Submitting to Corpus...</span>'
    $(this).find('td').each (index) ->
      if index == 0
        return
      else if index == 1
        $(this).attr('colspan', '12')
        $(this).removeClass('alt-col')
        $(this).removeClass('text-center')
        $(this).addClass('feedback-col')
      else
        $(this).remove()

    $('.feedback-col').html(loader)
    submit_to_corpus(data)



window.submit_to_corpus = (attachment_data) ->
  # actual submission
  $.ajax(
    url: '/escalations/api/v1/escalations/sdr/disputes/submit_to_corpus'
    method: 'POST'
    headers: headers
    data: attachment_data
    success: (response) ->
      att_feedback_col = $('.submit-attachment-row[data-id=' + response.data + '] .feedback-col')
      success_msg = "<div class='inline-msg success-msg'>Attachment successfully submitted to Corpus.</div>"
      $(att_feedback_col).html(success_msg)

    error: (error) ->
      att_feedback_col = $('.submit-attachment-row[data-id=' + response.data + '] .feedback-col')
      err_msg = "<div class='inline-msg error-msg'>Unable to submit attachment to Corpus, please try again later.</div>"
      $(att_feedback_col).html(err_msg)
  )



$ ->
  beautify_email_headers()
  beautify_details_field()

  # Check / enable button (make sure each attachment has a category selected)
  $(document).on 'change', '.email-category', ->
    enable_send_to_corpus()

  $('#submitCorpus').click () ->
    prep_submit_to_corpus()

  # Initialize send to corpus dialog
  $('#send-to-corpus-wrapper').dialog({autoOpen : false, width: 1000});

  # Select / deselect all attachments
  $('.corpus-all-attachments').click () ->
    checked = $('.corpus-all-attachments').is(':checked')
    $('.corpus-attachment').each () ->
      $(this).prop('checked', checked)
