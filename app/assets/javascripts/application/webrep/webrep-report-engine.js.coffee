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

window.refresh_multi_open_tickets_table = (user_ids)->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    users: user_ids,
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

        datatable = $('#multi_user_open_tickets').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed
        # json.data.ticket_count
        # json.data.entries_count
        # json.data.customer_count
        # json.data.guest_count
        # json.data.email_count
        # json.data.web_count
        # json.data.email_web_count

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
        datatable = $('#single_user_closed_tickets').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed
        # json.data.ticket_count
        # json.data.entries_count
        # json.data.customer_count
        # json.data.guest_count
        # json.data.email_count
        # json.data.web_count
        # json.data.email_web_count

    error: (response) ->
        #$('#refresh-working-msg').hide()
        #$('#refresh-error-msg').show()
        #$('#refresh-error-msg').html('An error occured while retrieving data')
  , this)

window.refresh_multi_closed_tickets_table = (user_ids)->
  from = localStorage.getItem('webrep_report_range_from')
  to = localStorage.getItem('webrep_report_range_to')

  data = {
    users: user_ids,
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

        datatable = $('#multi_user_closed_tickets').DataTable()
        datatable.clear();
        datatable.rows.add(json.data.table_data);
        datatable.draw();

        #References to other data points used to wrap this table, use as needed
        # json.data.ticket_count
        # json.data.entries_count
        # json.data.customer_count
        # json.data.guest_count
        # json.data.email_count
        # json.data.web_count
        # json.data.email_web_count

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

  alert(localStorage.getItem('webrep_report_range_from'))
  alert(localStorage.getItem('webrep_report_range_to'))
  user_id = $("#user_id").val()

  refresh_single_open_tickets_table(user_id)


$ ->
  $(document).ready ->
    window.set_initial_date_span()