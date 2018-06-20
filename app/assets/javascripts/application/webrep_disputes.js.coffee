window.populate_webrep_index_table = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep_disputes/disputes'
    method: 'GET'
    headers: headers
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        datatable = $('#disputes-index').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
      #$("#alert_message").addClass('alert alert-danger alert-dismissable').append(notice_html)
      #$("#create_research_submit_wait").addClass('hidden').hide()
      #$("#create_research_submit").show()
  , this)

window.populate_webrep_my_table = () ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep_disputes/disputes/my'
    method: 'GET'
    headers: headers
    success: (response) ->

      json = $.parseJSON(response)
      if json.error
        notice_html = "<p>Something went wrong: #{json.error}</p>"
        alert(json.error)
      else
        datatable = $('#my-disputes').DataTable()
        datatable.clear();
        datatable.rows.add(json.data);
        datatable.draw();

    error: (response) ->
      notice_html = "<p>Something went wrong: #{response.responseText}</p>"
  , this)

window.row_add_wlbl_button =(button_tag) ->
  wlbl_form = button_tag.form;
  data = {
    'urls': [ wlbl_form.getElementsByClassName('adjust-wlbl-urls-input')[0].value ]
    'trgt_list': wlbl_form.getElementsByClassName('adjust-wlbl-trgt_list-input')[0].value
    #'thrt_cats': wlbl_form.find('.adjust-wlbl-thrt_cats-list-input').val()
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-note-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep_disputes/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )

window.toolbar_add_wlbl_button =(button_tag) ->
  wlbl_form = button_tag.form;
  data = {
    'urls': [ wlbl_form.getElementsByClassName('adjust-wlbl-urls-input')[0].value ]
    'trgt_list': wlbl_form.getElementsByClassName('adjust-wlbl-trgt_list-input')[0].value
    #'thrt_cats': wlbl_form.find('.adjust-wlbl-thrt_cats-list-input').val()
    'note': wlbl_form.getElementsByClassName('adjust-wlbl-note-input')[0].value
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep_disputes/disputes/wlbl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )


window.add_reptool_bl_button = ->
  reptool_bl_form = $('#adjust-reptool-form')
  data = {
    'entries': reptool_bl_form.find('#adjust-reptool-bl-entries').val()
    'classifications': reptool_bl_form.find('#adjust-reptool-bl-classifications').val()
    'comment': reptool_bl_form.find('#adjust-reptool-bl-comment').val()
  }
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax(
    url: '/api/v1/escalations/webrep_disputes/disputes/reptool_bl'
    method: 'POST'
    headers: headers
    data: data
    dataType: 'json'
  )


