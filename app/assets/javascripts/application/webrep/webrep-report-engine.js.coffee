Chart.defaults.global.plugins.datalabels.display = false
Chart.defaults.global.tooltips = false;

globalDataLabels ={
  color: '#000'
  anchor: 'end'
  clamp: true
  font:
    weight: 600
    size: 12
  textStrokeColor:'white'
  textStrokeWidth: 3
  display: (ctx) ->
    return ctx.dataset.data[ctx.dataIndex] >= 1
  formatter: (value) ->
    return reduceDecimal(value)
}

getSum = (total, num) -> return total + num

reduceDecimal = (num) -> return Math.round(num * 100) / 100

window.populate_top_banner = ()->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    from: from,
    to: to
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/populate_top_banner'
    method: 'GET'
    headers: headers
    data: data
    success: (response) ->

      json = $.parseJSON(response)

      $('#total-valid-ticket-count').text(json.data.valid_tickets_total)
      $('#total-valid-entry-count').text(json.data.valid_entries_total)
      $('#total-invalid-ticket-count').text(json.data.invalid_tickets_total + ' Invalid Tickets')

  , this)


window.change_reported_week = (new_report_range_from, new_report_range_to)->
  localStorage.setItem 'webrep_report_range_from', new_report_range_from
  localStorage.setItem 'webrep_report_range_to', new_report_range_to

  window.refresh_visable_report_tab()

window.refresh_visable_report_tab = ()->
  if $('#dashboard-tab-list').length > 0
    user_id = $("#user_id").val()
    window.build_graph_ticket_entries_submitter()
    window.build_single_closed_email_entries_resolution_piechart()
    window.build_single_closed_web_entries_resolution_piechart()
    window.build_multi_closed_email_entries_resolution_piechart()
    window.build_multi_closed_web_entries_resolution_piechart()
    window.build_single_entries_closed_by_day_chart()
    window.build_multi_average_time_to_close_tickets()
    window.refresh_multi_closed_tickets_table()
    window.refresh_multi_open_tickets_table()
    window.refresh_single_open_tickets_table(user_id)
    window.refresh_single_closed_tickets_table(user_id)
    window.build_multi_entries_closed_by_owners_chart()
    window.build_multi_rulehits_for_fp_res_chart()
    window.build_multi_entries_closed_by_day_chart()
    window.build_multi_ticket_resolution_by_owner_chart()
    window.build_single_time_to_close_linechart()

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
      datatable = $('#table-multi-user-disputes-open').DataTable()
      datatable.clear();
      datatable.rows.add(json.data.table_data);
      datatable.draw();
      $("#open_multi_customer_count").html(json.data.customer_count)
      $("#open_multi_guest_count").html(json.data.guest_count)
      $("#open_multi_email_count").html(json.data.email_count)
      $("#open_multi_web_count").html(json.data.web_count)
      $("#open_multi_email_web_count").html(json.data.email_web_count)
      $("#open_multi_ticket_count").html(json.data.ticket_count)
      $("#open_multi_entry_count").html(json.data.entries_count)

    error: (response) ->

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
  , this)


window.set_date_label = () ->
  dateOptions = { year: 'numeric', month: 'long', day: 'numeric' };
  startdate = new Date(localStorage.getItem('webrep_report_range_from'))
  enddate = new Date(localStorage.getItem('webrep_report_range_to'))
  today = new Date()
  val = startdate.toLocaleDateString("en-US", dateOptions) + ' to ' + enddate.toLocaleDateString("en-US", dateOptions)
  if $('.dashboard-time label').length > 0
    $('.dashboard-time label')[0].innerHTML = val
    if today < enddate && today > startdate
      $('#ticket-view-shortcut').html("View Last Week's Tickets")
      $('#ticket-view-shortcut').switchClass('arrow-right','arrow-left')
    else
      $('#ticket-view-shortcut').html("View This Week's Tickets")
      $('#ticket-view-shortcut').switchClass('arrow-left','arrow-right')
  else
    return

window.set_initial_date_span = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  if from == null && to == null
    first = moment().startOf('isoWeek').toDate();
    last = moment().endOf('isoWeek').toDate();

    firstday = new Date(first).toUTCString();
    lastday = new Date(last).toUTCString();

    localStorage.setItem 'webrep_report_range_from', firstday
    localStorage.setItem 'webrep_report_range_to', lastday

  user_id = $("#user_id").val()

  prettyFromDate = new Date(localStorage.getItem('webrep_report_range_from')).toLocaleDateString("en-US")
  prettyToDate = new Date(localStorage.getItem('webrep_report_range_to')).toLocaleDateString("en-US")

  $('#tickets_date_range').val(prettyFromDate + " - " + prettyToDate)

  window.refresh_visable_report_tab()
  set_date_label()

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

      json = $.parseJSON(response)["data"]

      submitterGuestChartData = json["guest_chart_data"]
      submitterCustomerChartData = json["customer_chart_data"]
      submitterChartLabels = json["chart_labels"]

      Chart.defaults.global.defaultFontFamily = "'Open Sans', sans-serif"
      Chart.defaults.global.defaultFontSize = 10

      entriesSubmitter = new Chart($('#graph-ticket-entries-submitter'),
        type: 'bar'
        data:
          labels: submitterChartLabels
          datasets: [
            {
              label: 'Customer'
              backgroundColor: '#b5ebff'
              data: submitterCustomerChartData
            }
            {
              label: 'Guest'
              backgroundColor: '#E47433'
              data: submitterGuestChartData
            }]
        options:
          plugins:
            datalabels: globalDataLabels
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
          legend:
            display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  beginAtZero: true,
                  callback: (value) ->
                    if Number.isInteger(value)
                      return value
                    return
                }
              }
            ]
            xAxes: [
              {
                offset: true
                type: 'time'
                time:
                  unit: 'day'
                  displayFormats:
                    day: 'MMM DD'
                gridLines: display: false
                ticks: {
                  autoSkip: false
                  beginAtZero: true
                }
              }
            ]
      )

      multiUserEntries = new Chart($('#graph-multiuser-ticket-entries-submitter'),
        type: 'bar'
        data:
          labels: submitterChartLabels
          datasets: [
            {
              backgroundColor: '#b5ebff'
              data: submitterCustomerChartData
            }
            {
              backgroundColor: '#E47433'
              data: submitterGuestChartData
            }
          ]
        options:
          plugins:
            datalabels: globalDataLabels
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  beginAtZero: true,
                  callback: (value) ->
                    if Number.isInteger(value)
                      return value
                    return
                }
              }
            ]
            xAxes: [
              {
                offset: true
                type: 'time'
                time:
                  unit: 'day'
                  displayFormats:
                    day: 'MMM DD'
                gridLines: display: false
                ticks: {
                  autoSkip: false
                }
              }
            ]
      )

    error: (response) ->
      console.log(response, 'Error building chart')
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

      json = $.parseJSON(response)["data"]

      emailEntryResolutionLabels = json["chart_labels"]
      emailEntryData = json["chart_data"]

      tableData = json["table_data"]

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
              '#b5ebff'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
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
      console.log(response, 'Error building chart')
  )


window.build_single_time_to_close_linechart = () ->

  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()

  data = {
    from: from,
    to: to,
    user_id: user_id
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/ticket_time_to_close_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]

      closedTicketNumbers = json["ticket_numbers"]
      timeToCloseTickets = json["close_times"]
      if closedTicketNumbers.length == 0
        current_canvas = $('#time-to-close-tickets-linechart')
        current_graph = $(current_canvas)[0].getContext('2d')
        graph_wrapper = $('#time-to-close-tickets-linechart').parent()
        current_canvas[0].height = 100
        $(current_graph)[0].clearRect(0, 0,  current_canvas[0].width, current_canvas[0].height)
        unless $('#time-to-close-tickets-linechart-no-data').length
          $(graph_wrapper).append('<span id="time-to-close-tickets-linechart-no-data" class="missing-data graph-missing-data-flag">No data for this date range.</span>')
      else
        if $('#time-to-close-tickets-linechart-no-data').length
          $('#time-to-close-tickets-linechart-no-data').remove()

        allTimeToClose = undefined
        averageTimeToClose = 0
        if timeToCloseTickets.length
          allTimeToClose = timeToCloseTickets.reduce((a, b) ->
            a + b
          )
          averageTimeToClose = allTimeToClose / timeToCloseTickets.length
          averageTimeToClose = Math.round(averageTimeToClose * 100)/100


        window.averageTimeToCloseLabel(averageTimeToClose)


        timeCloseTicketsDataSets = [
          {
            data: timeToCloseTickets
            label: 'Time to Close:'
            backgroundColor: '#b5ebff'
            borderColor: '#55a3c1'
            borderWidth: 2
            fill: true
            lineTension: 0
          }
        ]

        closeTicketsChart = new Chart($('#time-to-close-tickets-linechart'),
          type: 'line'
          data:
            labels: closedTicketNumbers
            datasets: timeCloseTicketsDataSets
          options:
            hover:
              mode: null
            responsive: true
            maintainAspectRatio: false
            legend: false
            elements:
              point:
                radius: 0
            scales:
              yAxes: [
                {
                  gridLines:
                    display: false
                  ticks: {
                    min: 0
                    precision: 1
                    callback: (value, index, values) ->
                      return Number(value).toFixed(1) + ' hr'
                  }
                }
              ]
              xAxes: [
                {
                  gridLines:
                    display: false
                  scaleLabel: {
                    display: true,
                    labelString: 'Tickets'
                  }
                  ticks: {
                    display: false
                  }
                }
              ]
            annotation: {
              annotations: [
                {
                  type: 'line'
                  drawTime: 'afterDatasetsDraw'
                  mode: 'horizontal'
                  scaleID: 'y-axis-0'
                  value: averageTimeToClose
                  borderColor: '#304A60'
                  borderWidth: 1
                  label: {
                    backgroundColor: 'transparent'
                    fontStyle: 'normal'
                    fontColor: '#666'
                    fontSize: 14
                    content: 'Average: ' + averageTimeToClose + ' hr'
                    position: 'right'
                    yAdjust: -10
                    enabled: true
                  }
                }]
            })


    error: (response) ->
      console.log(response, 'Error building chart')
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

      json = $.parseJSON(response)["data"]

      emailEntryResolutionLabels = json["chart_labels"]
      emailEntryData = json["chart_data"]

      tableData = json["table_data"]

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
              '#b5ebff'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
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
      console.log(response, 'Error building chart')
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

      json = $.parseJSON(response)["data"]

      emailEntryResolutionLabels = json["chart_labels"]
      emailEntryData = json["chart_data"]

      tableData = json["table_data"]

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
              '#b5ebff'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
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
      console.log(response, 'Error building chart')
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

      json = $.parseJSON(response)["data"]

      emailEntryResolutionLabels = json["chart_labels"]
      emailEntryData = json["chart_data"]

      tableData = json["table_data"]

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
              '#b5ebff'
              '#666'
            ]
            data: emailEntryData
          } ]
        options:
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
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
      console.log(response, 'Error building chart')
  )


window.build_single_entries_closed_by_day_chart = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()

  cb_all_tix = $('input.all-ticket')[0]
  cb_types_tix = $('input.group-ticket')[0]

  $(cb_all_tix).checked = true
  $(cb_types_tix).checked = true

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

      json = $.parseJSON(response)['data']

      ticketTypeChartLabels = json['report_labels']
      ticketTypeTotalData = json['report_total_data']
      ticketTypeWData = json['report_w_data']
      ticketTypeEData = json['report_e_data']
      ticketTypeEWData = json['report_ew_data']

      total_entries = 0
      i = 0
      while i < ticketTypeTotalData.length
        total_entries += ticketTypeTotalData[i] << 0
        i++

      if total_entries == 0
        current_canvas = $('#graph-ticket-entries-closed')
        current_graph = $(current_canvas)[0].getContext('2d')
        graph_wrapper = $('#graph-ticket-entries-closed').parent()
        current_canvas[0].height = 100
        $(current_graph)[0].clearRect(0, 0,  current_canvas[0].width, current_canvas[0].height)
        unless $('#graph-ticket-entries-closed-no-data').length
          $(graph_wrapper).append('<span id="graph-ticket-entries-closed-no-data" class="missing-data graph-missing-data-flag">No data for this date range.</span>')

      else
        if $('#graph-ticket-entries-closed-no-data').length
          $('#graph-ticket-entries-closed-no-data').remove()

        window.userTicketClosedGraphDatasets = [
          {
            label: 'Total Ticket Entries'
            backgroundColor: '#b5ebff'
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
            plugins:
              datalabels: globalDataLabels
            barPercentage: 1
            hover:
              mode: null
            responsive: true
            maintainAspectRatio: false
            legend:
              display: false
            title:
              display: true
              position: 'bottom'
            scales:
              yAxes: [
                {
                  gridLines:
                    display: false
                  ticks: {
                    beginAtZero: true
                    callback: (value) ->
                      if Number.isInteger(value)
                        return value
                      return
                  }
                }
              ]
              xAxes: [
                {
                  categoryPercentage: 1,
                  barPercentage: 1,
                  offset: true
                  type: 'time'
                  time:
                    unit: 'day'
                    displayFormats:
                      day: 'MMM DD'
                  gridLines:
                    display: false
                  ticks: {
                    autoSkip: false
                  }
                }
              ]
        )


    error: (response) ->
      console.log(response, 'Error building chart')
  )
#### Multi User Graphs #####

window.build_multi_entries_closed_by_day_chart = () =>
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    from: from,
    to: to,
    users: team_ids['team']
  }

  cb_all_tix = $('input.all-ticket')[0]
  cb_types_tix = $('input.group-ticket')[0]

  $(cb_all_tix).checked = true
  $(cb_types_tix).checked = true

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/ticket_entries_closed_by_day_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]

      totalTicketEnties = json["report_total_data"]
      emailTicketEntries = json["report_e_data"]
      webTicketEntries = json["report_w_data"]
      ewTicketEntries = json["report_ew_data"]

      dateRange = json["report_labels"]

      totalTicketEntriesbyType = [
        {
          label: 'Total Ticket Entries'
          backgroundColor: '#b5ebff'
          data: totalTicketEnties
        }
        {
          label: 'E'
          backgroundColor: '#8cc63f'
          data: emailTicketEntries
        }
        {
          label: 'W'
          backgroundColor: '#E47433'
          data: webTicketEntries
        }
        {
          label: 'EW'
          backgroundColor: '#BA55D3'
          data: ewTicketEntries
        }
      ]


      window.multiuser_ticket_type_totals = new Chart($('#graph-multiuser-ticket-entries-closed'),
        type: 'bar'
        data:
          labels: dateRange
          datasets: totalTicketEntriesbyType
        options:
          plugins:
            datalabels: globalDataLabels
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: {
                  display: true
                  color: '#f2f2f2'
                }
                ticks: {
                  beginAtZero: true,
                  callback: (value) ->
                    if Number.isInteger(value)
                      return value
                    return
                }
              }
            ]
            xAxes: [
              {
                offset: true
                type: 'time'
                time:
                  unit: 'day'
                  displayFormats:
                    day: 'MMM DD'
                gridLines: {
                  display: false
                }
                ticks: {
                  autoSkip: true
                }
                scale: 'data'
              }
            ]
      )

      window.updateGraph = (label, barGraphName, e) ->

        originalData = []

        if barGraphName == 'userTicketClosedGraph'
          originalData = window.userTicketClosedGraphDatasets
        else if barGraphName == 'multiuser_ticket_type_totals'
          originalData = totalTicketEntriesbyType
        else
          alert 'Graph with name ' + barGraphName + ' is not defined'
          return

        if originalData != undefined
          if $(e)[0].checked
            currentData = window[barGraphName].data.datasets
            window[barGraphName].data.datasets = currentData.concat originalData.filter (x) -> label.indexOf(x.label) >= 0
            window[barGraphName].update()
          else
            currentData = window[barGraphName].data.datasets
            window[barGraphName].data.datasets = currentData.filter (x) -> label.indexOf(x.label) < 0
            window[barGraphName].update()


    error: (response) ->
      console.log(response, 'Error building chart')
  )
#### Multi User Graphs #####

window.build_multi_ticket_resolution_by_owner_chart = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    from: from,
    to: to,
    users: team_ids['team']
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/ticket_entry_resolution_by_ticket_owner'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]

      ticketOwners = json["ticket_owners"]
      fixedFPTickets = json["fixed_fp_tickets"]
      fixedFNTickets = json["fixed_fn_tickets"]
      unchangedTickets = json["unchanged_tickets"]
      otherTickets = json["other_tickets"]

      resolutionsByOwner = new Chart($('#ticket-resolutions-by-owner'),
        type: 'bar'
        data:
          labels: ticketOwners
          datasets: [
            {
              label: 'Fixed FP'
              backgroundColor: '#b5ebff'
              data: fixedFPTickets
            }
            {
              label: 'Fixed FN'
              backgroundColor: '#f9cf81'
              data: fixedFNTickets
            }
            {
              label: 'Unchanged'
              backgroundColor: '#999'
              data: unchangedTickets
            }
            {
              label: 'Other'
              backgroundColor: '#E47433'
              data: otherTickets
            }
          ]
        options:
          plugins:
            datalabels: globalDataLabels
          hover:
            mode: null
          responsive: true
          maintainAspectRatio: false
          title:
            display: false
          legend: display: false
          scales:
            yAxes: [
              {
                gridLines: display: false
                ticks: {
                  beginAtZero: true,
                  callback: (value) ->
                    if Number.isInteger(value)
                      return value
                    return
                }
              }
            ]
            xAxes: [
              {
                gridLines: display: false
              }
            ]
      )

    error: (response) ->
      console.log(response, 'Error building chart')
  )



#  Ticket entries closed by ticket owner

window.build_multi_entries_closed_by_owners_chart = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    from: from,
    to: to,
    users: team_ids['team']
  }

  $("#ticket-entries-closed-by-owner").empty()

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/ticket_entries_closed_by_ticket_owner_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]
      ticketOwners = json['report_labels']
      ticketEntriesByOwner = json['report_data']

      totalEntries = ticketEntriesByOwner.reduce(getSum)
      ticketOwners.push('Total Entries')
      ticketEntriesByOwner.push(totalEntries)

      total_entries = 0
      i = 0
      while i < ticketEntriesByOwner.length
        total_entries += ticketEntriesByOwner[i] << 0
        i++

      if total_entries == 0
        current_canvas = $('#ticket-entries-closed-by-owner')
        current_graph =  $(current_canvas)[0].getContext('2d')
        graph_wrapper = $('#ticket-entries-closed-by-owner').parent()
        current_canvas[0].height = 100
        $(current_graph)[0].clearRect(0, 0,  current_canvas[0].width, current_canvas[0].height)
        unless $('#ticket-entries-closed-by-owner-no-data').length
          $(graph_wrapper).append('<span id="ticket-entries-closed-by-owner-no-data" class="missing-data graph-missing-data-flag">No data for this date range.</span>')

      else
        if $('#ticket-entries-closed-by-owner-no-data').length
          $('#ticket-entries-closed-by-owner-no-data').remove()

        entriesClosedByOwner = new Chart($('#ticket-entries-closed-by-owner'),
          type: 'horizontalBar'
          responsive: true
          maintainAspectRatio: false
          data:
            labels: ticketOwners
            datasets: [ {
              backgroundColor: '#b5ebff'
              data: ticketEntriesByOwner
            } ]
          options:
            plugins:
              datalabels: globalDataLabels
            hover:
              mode: null
            responsive: true
            maintainAspectRatio: false
            legend: display: false
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
                    beginAtZero: true,
                    callback: (value) ->
                      if Number.isInteger(value)
                        return value
                      return
                  }
                  scaleLabel: {
                    display: true,
                    labelString: 'Closed Ticket Entries'
                  }
                }
              ]
        )

    error: (response) ->
      console.log(response, 'Error building chart')
  )

window.build_multi_average_time_to_close_tickets = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    from: from,
    to: to,
    users: team_ids['team']
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/average_time_to_close_tickets_by_ticket_owner_report'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]

      ticketOwners = json["report_labels"]
      avgTimeToCloseTickets = json["report_data"]

      totalTime = avgTimeToCloseTickets.reduce(getSum) / avgTimeToCloseTickets.length
      ticketOwners.push('Team Average')
      avgTimeToCloseTickets.push(totalTime)

      total_tickets = 0
      i = 0
      while i < avgTimeToCloseTickets.length
        total_tickets += avgTimeToCloseTickets[i] << 0
        i++

      if total_tickets == 0
        current_canvas = $('#avg-time-to-close-tickets')
        current_graph =  $(current_canvas)[0].getContext('2d')
        graph_wrapper = $('#avg-time-to-close-tickets').parent()
        current_canvas[0].height = 100
        $(current_graph)[0].clearRect(0, 0,  current_canvas[0].width, current_canvas[0].height)
        unless $('#avg-time-to-close-tickets-no-data').length
          $(graph_wrapper).append('<span id="avg-time-to-close-tickets-no-data" class="missing-data graph-missing-data-flag">No data for this date range.</span>')

      else
        if $('#avg-time-to-close-tickets-no-data').length
          $('#avg-time-to-close-tickets-no-data').remove()

        avgTimeToCloseNew = new Chart($('#avg-time-to-close-tickets'),
          type: 'horizontalBar'
          data:
            labels: ticketOwners
            datasets: [ {
              backgroundColor: '#b5ebff'
              data: avgTimeToCloseTickets
            } ]
          options:
            plugins:
              datalabels: globalDataLabels
            hover:
              mode: null
            responsive: true
            maintainAspectRatio: false
            legend: display: false
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
                    min: 0
                  }
                  scaleLabel: {
                    display: true,
                    labelString: 'Hours'
                  }
                }
              ]
        )

    error: (response) ->
      console.log(response, 'Error building chart')
  )

window.build_multi_rulehits_for_fp_res_chart = () ->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')
  user_id = $("#user_id").val()
  team_ids = $.parseJSON("{\"team\":" + $("#team_ids").val() + "}")
  data = {
    from: from,
    to: to,
    users: team_ids['team']
  }

  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/escalations/api/v1/escalations/webrep/reports/rulehits_for_false_positive_resolutions'
    method: 'GET'
    headers: headers
    data: data
    dataType: 'json'
    success: (response) ->

      json = $.parseJSON(response)["data"]

      fpRules = json["rules"] #['a500', 'alx_ cln', 'mute_phish', 'sbl', 'srch', 'suwl', 'trd_mal']
      totalRuleHits = json["rule_hits"] #[ 5, 18, 9, 14, 4, 7, 3]

      total_hits = 0
      i = 0
      while i < totalRuleHits.length
        total_hits += totalRuleHits[i] << 0
        i++

      if total_hits == 0
        current_canvas = $('#rule-hits-fp-resolutions')
        current_graph = $(current_canvas)[0].getContext('2d')
        graph_wrapper = $('#rule-hits-fp-resolutions').parent()
        current_canvas[0].height = 100
        $(current_graph)[0].clearRect(0, 0,  current_canvas[0].width, current_canvas[0].height)
        unless $('#rule-hits-fp-resolutions-no-data').length
          $(graph_wrapper).append('<span id="rule-hits-fp-resolutions-no-data" class="missing-data graph-missing-data-flag">No data for this date range.</span>')

      else
        if $('#rule-hits-fp-resolutions-no-data').length
          $('#rule-hits-fp-resolutions-no-data').remove()

        ruleHitsFPResolutions = new Chart($('#rule-hits-fp-resolutions'),
          type: 'horizontalBar'
          data:
            labels: fpRules
            datasets: [ {
              backgroundColor: '#b5ebff'
              data: totalRuleHits
            } ]
          options:
            plugins:
              datalabels: globalDataLabels
            hover:
              mode: null
            responsive: true
            maintainAspectRatio: false
            legend: display: false
            scales:
              yAxes: [
                {
                  gridLines: display: false
                }
              ]
              xAxes: [
                {
                  gridLines: display: false
                  ticks: {
                    beginAtZero: true,
                    callback: (value) ->
                      if Number.isInteger(value)
                        return value
                      return
                  }
                  scaleLabel: {
                    display: true,
                    labelString: 'Total Ticket Entries with FP Resolutions'
                  }
                }
              ]
        )

    error: (response) ->
      console.log(response, 'Error building chart')
  )

$ ->

  $('#export-reports-button').on "click", ->
    paramObject = {}
    $('.report-checkbox').each ->
      if this.checked
        paramObject[this.name] = true
        undefined
      else
        paramObject[this.name] = false
        undefined

    paramObject.startdate = localStorage.getItem('webrep_report_range_from')
    paramObject.enddate = localStorage.getItem('webrep_report_range_to')
    window.location = "/escalations/webrep/dashboard.xlsx?" + $.param(paramObject);

  window.set_initial_date_span()
  $('#tickets_date_range').daterangepicker()
  $('button.icon-calendar').click ->
    $('#tickets_date_range').trigger 'click'

  if $('#dashboard-tab-list').length > 0

    window.set_initial_date_span()
    $('#tickets_date_range').daterangepicker()
    $('button.icon-calendar').click ->
      $('#tickets_date_range').trigger 'click'

    $('#tickets_date_range').on 'apply.daterangepicker', (ev, picker) ->
      firstday = new Date(picker.startDate).toUTCString();
      lastday = new Date(picker.endDate).toUTCString();

      localStorage.setItem 'webrep_report_range_from', picker.startDate
      localStorage.setItem 'webrep_report_range_to', picker.endDate
      user_id = $("#user_id").val()
      set_date_label()
      window.refresh_visable_report_tab()

    $('#ticket-view-shortcut').click ->
      if this.innerHTML == "View Last Week's Tickets"
        d = new Date;
        d.setDate(d.getDate() - 7)

        first = moment(d).startOf('isoWeek').toDate();
        last = moment(d).endOf('isoWeek').toDate();

        firstday = new Date(first).toUTCString();
        lastday = new Date(last).toUTCString();

        localStorage.setItem 'webrep_report_range_from', firstday
        localStorage.setItem 'webrep_report_range_to', lastday
      else
        first = moment().startOf('isoWeek').toDate();
        last = moment().endOf('isoWeek').toDate();

        firstday = new Date(first).toUTCString();
        lastday = new Date(last).toUTCString();

        localStorage.setItem 'webrep_report_range_from', firstday
        localStorage.setItem 'webrep_report_range_to', lastday

      user_id = $("#user_id").val()
      set_date_label()
      window.refresh_visable_report_tab()

    window.refresh_visable_report_tab()
    window.populate_top_banner()