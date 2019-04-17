# WIP for this coffee file
#$ ->
#  $('#new-file-rep-form').submit (e) ->
#    e.preventDefault()
#    $('#loader-modal').modal({
#      backdrop: 'static',
#      keyboard: false
#    })
#    shas_list = this.shas_list.value
#    disposition_suggested = this.disposition_suggested.value
#    assignee = this.assignee.value
#
#    std_msg_ajax(
#      url: '/escalations/api/v1/escalations/file_rep/disputes'
#      method: 'POST'
#      data:
#        shas_list: shas_list,
#        suggested_disposition: suggested_disposition,
#        assignee: assignee
#      success: (response) ->
#        $('#loader-modal').modal 'hide'
#        std_msg_success('File Reputation Dispute Created.', [], reload: true)
#      error: (response) ->
#        $('#loader-modal').modal 'hide'
#        std_api_error(response, "File Reputation Dispute was not created.", reload: false)
#    )
