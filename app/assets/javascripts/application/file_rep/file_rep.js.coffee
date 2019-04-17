$ ->



  file_rep_url = $('#file-rep-datatable').data('source')

  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax: file_rep_url
    pagingType: 'full_numbers'
    columns: [
      {
        data: 'id'
        className: 'font-weight-bold'
      }
      {
        data: 'status'
        className: 'font-weight-bold'
      }
      {
        data: 'resolution'
      }
      { data: 'file_name'}
      {
        data: 'sha256_hash'
        render: (data) ->
          return '<code id="' + data + '_sha" title="' + data + '" class="esc-tooltipped tooltipstered file_rep_sha">' + data + '</code>'
      }
      {
        data: 'file_size'
        render: (data) ->
          return '<span>' + data + ' bytes </span>'
      }
      { data: 'sample_type'}
      {
        data: 'disposition'
        className: 'text-capitalize'
        render: (data) ->
          if data == 'malicious'
            return '<span class="malicious">malicious</span>'
          else
          return '<span>clean</span>'
      }
      {
        data: 'detection_name'
        render: (data) ->
          if data == null || data == undefined
            return '<span class="missing-data">Detection not found</span>'
          else
            return data
      }
      {
        data: null
        render: () ->
          return '<span>Detection created</span>'
      }
      {
        data: 'in_zoo'
        className: "alt-col in_zoo"
        render: (data) ->
#          in_zoo is a boolean but something in the render function parses this to a string.
          if data == "true"
            data = '<span class="glyphicon glyphicon-ok"></span>'
          else
            data = ''
          return data
      }
      {
        data: 'sandbox_score'
        render: (data, type, full, meta) ->
          if full['sandbox_under'] == "true"
            data = '<span>' + data + '</span>'
          else
            data = '<span class="overdue">' + data + '</span>'
          return data
      }
      {
        data: 'threatgrid_score'
        render: (data, type, full, meta) ->
          if full['threatgrid_under'] == "true"
            data = '<span>' + data + '</span>'
          else
            data = '<span class="overdue">' + data + '</span>'
          return data
      }
      { data: 'reversing_labs_score'}
      {
        data: 'disposition_suggested'
        className: 'text-capitalize'
        render: (data) ->
          if data == 'malicious'
            return '<span class="malicious">malicious</span>'
          else
            return '<span>clean</span>'
      }
      { data: 'created_at'}
      {
#        submitter Type
        data: null
        render: () ->
          return "<span>submitter Type</span>"
      }
      {
        data: 'customer_name'
      }
      {
        data: 'customer_company_name'
      }
      {
        data: 'customer_email'
      }
      {
        data: 'assignee'
        className: "alt-col"
        render: (data) ->
          if data == undefined
            data = '<span class="missing-data">Unassigned</span> <span title="Assign to me" class="esc-tooltipped tooltipstered"><button id="index_ticket_assign" class="take-ticket-button" onClick="take_disputes()"/></span>'
          else
            data = data + '<span title="Assign to me" class="esc-tooltipped tooltipstered"><button id="index_ticket_assign" class="take-ticket-button" onClick="take_disputes()"/></span>'
          return data
      }
    ]

  $('.toggle-vis-file-rep').each ->
#    toggle visible columns
      table = $('#file-rep-datatable').DataTable()
      column = table.column($(this).attr('data-column'))
      checkbox = $(this).find('input')
      if $(checkbox).prop('checked')
        column.visible true
      else
        column.visible false
      $(this).on 'click', ->
        $(checkbox).prop 'checked', !checkbox.prop('checked')
        column.visible !column.visible()
        return

      $(checkbox).on 'click', ->
        $(checkbox).prop 'checked', !checkbox.prop('checked')
        return
      return
      checkbox = $(this).find('input')

    $(document).on 'click ','.file_rep_sha', (e) ->
#      copy SHA on click
      copy_text_id = e.target.id
      copy_text = document.getElementById(copy_text_id);
      selection = window.getSelection();
      range = document.createRange();
      range.selectNodeContents(copy_text);
      selection.removeAllRanges();
      selection.addRange(range);
      document.execCommand("Copy");


#  dbinebri: file rep form - new ticket jquery here
  $('#new-file-rep-form').on 'submit', (e) ->
    e.preventDefault()

    shas_input_type = $('#shas_input_type').val()
    shas_full_text = $('#shas_list').val()
    disposition = $('#disposition_suggested').val()
    assignee = $('#assignee').val()

    shas_array = shas_full_text.split(/[\s,;]+/)

    if shas_array
      console.log "SHAS LIST HERE: " + shas_array + '\n'
      console.log '# OF SHA(s): \n' + shas_array.length + '\n'
      console.log "SUGGESTED DISPOSITION: \n" + disposition + "\n"
      console.log "ASSIGNEE: \n" + assignee + "\n"

#     # review below, I feel this form validation (empty lines or hex)
#     # should be in a separate ticket, or its extraneous

#    i = undefined
#    curr_sha_object = {}
#    regexp = /^[0-9A-Fa-f]+$/

#      while i < shas_array.length
#        if shas_array[i] == ''
#          continue
#
#        else if regexp.test(shas_array[i])
#
#          curr_sha_object =
#            sha: shas_array[i]
#            disposition_suggested: disposition
#            assignee: assignee
#          regexp.lastIndex = 0
#
#          console.log curr_sha_object
#
#        else if regexp.test(shas_array[i] == false)
#
#          regexp.lastIndex = 0
#          console.log 'This sha is incorrect: ' + shas_array[i + '\n']
#
#        else
#          console.log 'Unknown error occured. Please try again.'
