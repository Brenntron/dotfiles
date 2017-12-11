window.set_rule_doc_status =(rule_id, new_value) ->
  headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()}
  $.ajax {
    url: "/api/v1/rules/" + rule_id + "/snort_doc_status"
    type: 'PATCH'
    dataType: 'json'
    headers: headers
    data:
      snort_doc_status: new_value
    error_prefix: "Snort Doc status was not updated."
    failure_reload: false
  }

