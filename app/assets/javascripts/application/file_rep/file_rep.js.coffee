$ ->

  file_rep_url = $('#file-rep-datatable').data('source')

  window.get_search_type = () ->
    if !localStorage.search_type
      localStorage.search_type = 'standard'
    return localStorage.search_type

  window.get_search_name = () ->

    if localStorage.search_type = 'standard'

      current_url = window.location.href
      status_param_regex = /f=(.*)/
      current_name = status_param_regex.exec(current_url)

      if current_url.match('f=') && current_name
       localStorage.search_name = current_name[1]
      else
        localStorage.search_name = 'all'

    else if localStorage.search_type = 'named'
      localStorage.search_name = $('#saved-search .saved-search').text()

    return localStorage.search_name

  window.get_search_condition = () ->
      if localStorage.search_type = 'standard'
        return ''

  window.build_data = () ->

    search_type = window.get_search_type()
    search_name = window.get_search_name()
    search_condition = window.get_search_condition()

    return data =
            search_type : window.get_search_type()
            search_name : window.get_search_name()


  $('#file-rep-datatable').dataTable
    processing: true
    serverSide: true
    ajax:
      url: file_rep_url
      data: window.build_data()
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
          return '<code id="' + data + '_sha" title="' + data + '" class="esc-tooltipped file_rep_sha">' + data + '</code>'
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
#          to lowercase this and all other comparison thangs

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

    $(document).on 'click', '.saved-search', () ->
      localStorage.search_type = 'named'
