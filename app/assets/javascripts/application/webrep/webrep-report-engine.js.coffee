window.change_reported_week = (new_report_range_from, new_report_range_to)->
  localStorage.setItem 'webrep_report_range_from', new_report_range_from
  localStorage.setItem 'webrep_report_range_to', new_report_range_to

  window.refresh_visable_report_tab()

window.refresh_visable_report_tab = ()->
  alert('refreshing')
  #most likely called from changing dates, when this is called
  #grab all visual components and refresh their data


window.refresh_single_open_tickets_table = (user_id)->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    users: [user_id],
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/open_tickets_report'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)

      if json.error
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')

      else
        #$('#refresh-error-msg').hide()
        #$('#refresh-working-msg').show()
        #$('#refresh-working-msg').html('Table data updating correctly')
        #$('#dispute-index-title').text(json['title'])
        datatable = $('#table-user-disputes-open').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed

        $("#open_single_customer_count").html(json.data.customer_count)
        $("#open_single_guest_count").html(json.data.guest_count)
        $("#open_single_email_count").html(json.data.email_count)
        $("#open_single_web_count").html(json.data.web_count)
        $("#open_single_email_web_count").html(json.data.email_web_count)

        $("#open_single_ticket_count").html(json.data.ticket_count)
        $("#open_single_entry_count").html(json.data.entries_count)
    error: (response) ->
      #$('#refresh-working-msg').hide()
      #$('#refresh-error-msg').show()
      #$('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.refresh_multi_open_tickets_table = ()->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    users: team_ids['team'],
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/open_tickets_report'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')

      else

        datatable = $('#table-multi-user-disputes-open').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed

        $("#open_multi_customer_count").html(json.data.customer_count)
        $("#open_multi_guest_count").html(json.data.guest_count)
        $("#open_multi_email_count").html(json.data.email_count)
        $("#open_multi_web_count").html(json.data.web_count)
        $("#open_multi_email_web_count").html(json.data.email_web_count)

        $("#open_multi_ticket_count").html(json.data.ticket_count)
        $("#open_multi_entry_count").html(json.data.entries_count)

    error: (response) ->
      #$('#refresh-working-msg').hide()
      #$('#refresh-error-msg').show()
      #$('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.refresh_single_closed_tickets_table = (user_id)->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    users: [user_id],
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_tickets_report'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)

      if json.error
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')

      else
        #$('#refresh-error-msg').hide()
        #$('#refresh-working-msg').show()
        #$('#refresh-working-msg').html('Table data updating correctly')
        #$('#dispute-index-title').text(json['title'])
        datatable = $('#table-user-disputes-closed').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed

        $("#closed_single_customer_count").html(json.data.customer_count)
        $("#closed_single_guest_count").html(json.data.guest_count)
        $("#closed_single_email_count").html(json.data.email_count)
        $("#closed_single_web_count").html(json.data.web_count)
        $("#closed_single_email_web_count").html(json.data.email_web_count)

        $("#closed_single_ticket_count").html(json.data.ticket_count)
        $("#closed_single_entry_count").html(json.data.entries_count)

    error: (response) ->
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.refresh_multi_closed_tickets_table = ()->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")

  data = {
    users: team_ids['team'],
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_tickets_report'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)

      if json.error
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')

      else

        datatable = $('#table-multi-user-disputes-closed').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        $("#closed_multi_customer_count").html(json.data.customer_count)
        $("#closed_multi_guest_count").html(json.data.guest_count)
        $("#closed_multi_email_count").html(json.data.email_count)
        $("#closed_multi_web_count").html(json.data.web_count)
        $("#closed_multi_email_web_count").html(json.data.email_web_count)

        $("#closed_multi_ticket_count").html(json.data.ticket_count)
        $("#closed_multi_entry_count").html(json.data.entries_count)

    error: (response) ->
      #$('#refresh-working-msg').hide()
      #$('#refresh-error-msg').show()
      #$('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.set_initial_date_span = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  if from == null && to == null
    curr = new Date;
    first = curr.getDate() - curr.getDay();
    last = first + 6;

    firstday = new Date(curr.setDate(first)).toUTCString();
    lastday = new Date(curr.setDate(last)).toUTCString();



    localStorage.setItem 'webrep_report_range_from', firstday
    localStorage.setItem 'webrep_report_range_to', lastday

#  alert(localStorage.getItem('webrep_report_range_from'))
#  alert(localStorage.getItem('webrep_report_range_to'))
  user_id = $("#user_id").val()

  refresh_single_open_tickets_table(user_id)
  refresh_single_closed_tickets_table(user_id)

window.build_graph_ticket_entries_submitter = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/tickets_submitted_by_submitter_per_day'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      submitterGuestChartData = json["data"]["guest_chart_data"]
      submitterCustomerChartData = json["data"]["customer_chart_data"]
      submitterChartLabels = json["data"]["chart_labels"]

      Chart.defaults.global.defaultFontFamily = "'Open Sans', sans-serif"
      Chart.defaults.global.defaultFontSize = 10

      new Chart($('#graph-ticket-entries-submitter'),
        type: 'bar'
        data:
          labels: submitterChartLabels
          datasets: [
            {
              label: 'Customer'
              backgroundColor: '#6dbcdb'
              data: submitterCustomerChartData
            }
            {
              label: 'Guest'
              backgroundColor: '#3e5a72'
              data: submitterGuestChartData
            }]
        options:
          legend:
            display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  min: 0
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
      )

    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )

window.build_single_closed_email_entries_resolution_piechart = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()

  data = {
    from: from,
    to: to,
    users: [user_id],
    submission_types: ["e"]
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_ticket_entries_by_resolution_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      emailEntryResolutionLabels = json["data"]["chart_labels"]
      emailEntryData = json["data"]["chart_data"]

      tableData = json["data"]["table_data"]

      email_piechart_table = $('#closed-email-entries-resolution-table tbody')
      $(email_piechart_table).empty()

      $(tableData).each ->
        $(email_piechart_table).append('<tr><td>' + this.resolution + '</td><td class="text-center">' + this.percent + ' %</td><td class="text-center">' + this.count + '</td></tr>')

      Chart.defaults.global.defaultFontFamily = "'Open Sans', sans-serif"
      Chart.defaults.global.defaultFontSize = 10

      new Chart($('#closed-email-entries-resolution-piechart'),
        type: 'pie'
        data:
          labels: emailEntryResolutionLabels
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true
      )

    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )



window.build_single_closed_web_entries_resolution_piechart = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()


  data = {
    from: from,
    to: to,
    users: [user_id],
    submission_types: ["w"]
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_ticket_entries_by_resolution_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      emailEntryResolutionLabels = json["data"]["chart_labels"]
      emailEntryData = json["data"]["chart_data"]

      tableData = json["data"]["table_data"]

      web_piechart_table = $('#closed-web-entries-resolution-table tbody')
      $(web_piechart_table).empty()

      $(tableData).each ->
        $(web_piechart_table).append('<tr><td>' + this.resolution + '</td><td class="text-center">' + this.percent + ' %</td><td class="text-center">' + this.count + '</td></tr>')


      new Chart($('#closed-web-entries-resolution-piechart'),
        type: 'pie'
        data:
          labels: emailEntryResolutionLabels
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true
      )

    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )

#######

window.build_multi_closed_email_entries_resolution_piechart = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")

  data = {
    from: from,
    to: to,
    users: team_ids['team'],
    submission_types: ["e"]
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_ticket_entries_by_resolution_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      emailEntryResolutionLabels = json["data"]["chart_labels"]
      emailEntryData = json["data"]["chart_data"]

      tableData = json["data"]["table_data"]

      email_piechart_table = $('#multi-closed-email-entries-resolution-table tbody')
      $(email_piechart_table).empty()

      $(tableData).each ->
        $(email_piechart_table).append('<tr><td>' + this.resolution + '</td><td class="text-center">' + this.percent + ' %</td><td class="text-center">' + this.count + '</td></tr>')

      new Chart($('#multi-email-entries-by-resolution-piechart'),
        type: 'pie'
        data:
          labels: emailEntryResolutionLabels
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true
      )

    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )


window.build_multi_closed_web_entries_resolution_piechart = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")

  data = {
    from: from,
    to: to,
    users: team_ids['team'],
    submission_types: ["w"]
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/closed_ticket_entries_by_resolution_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      emailEntryResolutionLabels = json["data"]["chart_labels"]
      emailEntryData = json["data"]["chart_data"]

      tableData = json["data"]["table_data"]

      web_piechart_table = $('#multi-closed-web-entries-resolution-table tbody')
      $(web_piechart_table).empty()

      $(tableData).each ->
        $(web_piechart_table).append('<tr><td>' + this.resolution + '</td><td class="text-center">' + this.percent + ' %</td><td class="text-center">' + this.count + '</td></tr>')

      new Chart($('#multi-web-entries-by-resolution-piechart'),
        type: 'pie'
        data:
          labels: emailEntryResolutionLabels
          datasets: [ {
            label: 'close-email-entries'
            backgroundColor: [
              '#3e5a72'
              '#6dbcdb'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          legend: false
          pieceLabel:
            render: (args) ->
              return args.percentage + '%'
            position: 'outside'
            segment: false
            precision: 2
            showZero: true
            fontStyle: 'bolder'
            overlap: false
            showActualPercentages: true
      )

    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )


window.build_single_entries_closed_by_day_chart = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()

  data = {
    from: from,
    to: to,
    users: [user_id]
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/ticket_entries_closed_by_day_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)

      ticketTypeChartLabels = json['data']['report_labels']
      ticketTypeTotalData = json['data']['report_total_data']
      ticketTypeWData = json['data']['report_w_data']
      ticketTypeEData = json['data']['report_e_data']
      ticketTypeEWData = json['data']['report_ew_data']

      window.userTicketClosedGraphDatasets = [
        {
          label: 'Total Ticket Entries'
          backgroundColor: '#6dbcdb'
          data: ticketTypeTotalData
        }
        {
          label: 'W'
          backgroundColor: '#E47433'
          data: ticketTypeWData
        }
        {
          label: 'E'
          backgroundColor: '#5FB665'
          data: ticketTypeEData
        }
        {
          label: 'EW'
          backgroundColor: '#C14B92'
          data: ticketTypeEWData
        }]


      window.userTicketClosedGraph = new Chart($('#graph-ticket-entries-closed'),
        type: 'bar'
        data:
          labels: ticketTypeChartLabels
          datasets: window.userTicketClosedGraphDatasets,
        options:
          legend:
            display: false
          title:
            display: true
            position: 'bottom'
            text: 'Dates'
          scales:
            yAxes: [
              {
                gridLines:
                  display: false
                ticks: {
                  min: 0
                }
              }
            ]
            xAxes: [
              {
                gridLines:
                  display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
      )


    error: (response) ->
      popup_response_error(response, 'Error building chart')
  )



$ ->
  $('#tickets_date_range').daterangepicker()
  $('button.icon-calendar').click ->
    $('#tickets_date_range').trigger 'click'


$ ->
  $('#tickets_date_range').on 'apply.daterangepicker', (ev, picker) ->
    start = picker.startDate.format('MMMM/DD/YYYY').split('/')
    end = picker.endDate.format('MMMM/DD/YYYY').split('/')
    val = start[0] + ' ' + start[1] + ', ' + start[2] + ' to ' + end[0] + ' ' + end[1] + ', ' + end[2]
    $('.dashboard-time label')[0].innerHTML = val

    firstday = new Date(picker.startDate).toUTCString();
    lastday = new Date(picker.endDate).toUTCString();

    localStorage.setItem 'webrep_report_range_from', picker.startDate
    localStorage.setItem 'webrep_report_range_to', picker.endDate
    user_id = $("#user_id").val()
    refresh_single_open_tickets_table(user_id)
    refresh_single_closed_tickets_table(user_id)
    return
  return


$ ->
  $(document).ready ->
    window.set_initial_date_span()
    window.build_graph_ticket_entries_submitter()
    window.build_single_closed_email_entries_resolution_piechart()
    window.build_single_closed_web_entries_resolution_piechart()
    window.build_multi_closed_email_entries_resolution_piechart()
    window.build_multi_closed_web_entries_resolution_piechart()
    window.build_single_entries_closed_by_day_chart()

    window.refresh_multi_closed_tickets_table()
    window.refresh_multi_open_tickets_table()