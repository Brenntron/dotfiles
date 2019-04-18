$ ->



  file_rep_url = $('#file-rep-datatable').data('source')

  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax: file_rep_url
    order: [ [
      16
      'desc'
    ] ]
    pagingType: 'full_numbers'
    keys:
      columns: ':not(:first-child)'
    columnDefs: [
      {
        # Making checkbox row unorderable
        targets: [ 0 ]
        orderable: false
        searchable: false
      }
      {
        targets: [ 1 ]
        className: 'id-col'
      }
      {
        # Bolds the status
        targets: [ 2 ]
        className: 'font-weight-bold'
      }
    ]
    columns: [
      {
        data:'id'
        render: (data) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" />'
      }
      {
#        need to zeropad this thing
        data: 'id'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + data + '">' + parseInt(data).pad(6) + '</a>'
      }
      { data: 'status' }
      { data: 'resolution' }
      {
        data: 'file_name'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + full['id'] + '">' + data + '</a>'
      }
      {
        data: 'sha256_hash'
        render: (data, type, full, meta) ->
          return '<a href="/escalations/file_rep/disputes/' + full['id'] + '"><span id="' + data + '_sha" title="' + data + '" class="esc-tooltipped file_rep_sha">' + data + '</span></a>'
      }
      {
        data: 'file_size'
        render: (data) ->
          return data + ' bytes'
      }
      { data: 'sample_type'}
      {
        data: 'disposition'
        render: (data) ->
          if data == 'Malicious'
            data = '<span class="malicious text-capitalize">Malicious</span>'
          else
            data =  '<span class="text-capitalize">' + data + '</span>'
          return data
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
            data = '<span class="score-col text-center">' + parseInt(data) + '</span>'
          else
            data = '<span class="overdue score-col text-center">' + parseInt(data) + '</span>'
          return data
      }
      {
        data: 'threatgrid_score'
        render: (data, type, full, meta) ->
          if full['threatgrid_under'] == "true"
            data = '<span class="score-col text-center">' + parseInt(data) + '</span>'
          else
            data = '<span class="overdue score-col text-center">' + parseInt(data) + '</span>'
          return data
      }
      { data: 'reversing_labs_score'}
      {
        data: 'disposition_suggested'
        render: (data) ->
          if data == 'Malicious'
            data = '<span class="malicious text-capitalize">Malicious</span>'
          else
            data =  '<span class="text-capitalize">' + data + '</span>'
          return data
      }
      { data: 'created_at'}
      {
#        Submitter Type
        data: null
        render: () ->
          return "Submitter Type"
      }
      { data: 'customer_name' }
      { data: 'customer_company_name' }
      { data: 'customer_email' }
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

    Number::pad = (size) ->
      s = String(this)
      while s.length < (size or 2)
        s = '0' + s
      s
