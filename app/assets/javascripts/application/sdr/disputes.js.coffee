$ ->
  $('#sdr-disputes-index').dataTable
    processing: true
    serverSide: true
    ajax:
      url: $('#usdr-disputes-index').data('source')
    pagingType: 'full_numbers'
    columns: [
      {
        data:'case_id'
        render: (data, type, full, meta) ->
          return '<input type="checkbox" onclick="toggleRow(this)" name="cbox" class="dispute_check_box" id="cbox' + data + '" value="' + data + '" data-sha="' + full['sha256_hash'] + '"/>'
      }
      {
        data: null
        orderable: false
        searchable: false
        sortable: false
        defaultContent: '<span></span>'
        width: '10px'
        render: ( data )->
          { is_important, was_dismissed } = data
          if is_important == "true" && was_dismissed == "true"
            return '<div class="container-important-tags ">' +
              '<div class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></div>' +
              '<div class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></div>' +
              '</div>'
          else if is_important == "true" && was_dismissed == "false"
            return '<span class="esc-tooltipped is-important highlight-second-review" tooltip title="Important"></span>'
          else if is_important == "false" && was_dismissed == "true"
            return '<span class="esc-tooltipped was-reviewed highlight-was-dismissed" tooltip title="Reviewed"></span>'
      }
      {
        data: 'case_id'
        render: (data, type, full, meta) ->
          return parseInt(data).pad(6)
      }
      {
        data: 'status'
      }
      {
        data: 'resolution'
      }
      {
        data: 'created_at'
        render: (data) ->
          if data
            return moment(data, "YYYY-MM-DD HH:mm").format("YYYY-MM-DD HH:mm")
          else
            return ''
      }
      {
        #age column
        width: '40px'
        render: (data, type, full, meta) ->
          { age, status } = full
          unless status == 'COMPLETED' || status == 'RESOLVED'
            if age.indexOf('hour') != -1
              hour = parseInt( age.split("h")[0] )
              if hour >= 3 && hour < 12
                age_class = 'ticket-age-over3hr'
              else if hour > 12
                age_class = 'ticket-age-over12hr'
            else if age.indexOf('minute') != -1
              age_class = ''
            else
              age_class = 'ticket-age-over12hr'
            return "<span class='#{age_class}'>#{age}</span>"
          # if status is "completed" or "resolved", no css class (orange/red) needed
          else
            return "<span>#{age}</span>"
      }
      {
        data: 'assignee'
#        className: "alt-col assignee-col"
        render: (data, type, full, meta) ->
          if data == 'vrtincom' || data == ""
            return 'Unassigned'
          return data
#          if full.current_user == data
#            return "<span id='owner_#{full.id}'> #{data} </span><button class='esc-tooltipped return-ticket-button inline-return-ticket-#{full.id}' title='Return ticket.' onclick='file_rep_return_dispute(#{full.id});'></button>"
#            return data
#          else if data == 'vrtincom' || data == ""
#            return "<span class='missing-data missing-data-index' id='owner_#{full.id}'>Unassigned</span> <span title='Assign to me' class='esc-tooltipped'><button class='take-ticket-button inline-take-dispute-#{full.id}' onClick='file_rep_take_dispute(#{full.id})'/></button></span>"
#            return 'Unassigned'
#          else
#            return data
      }
      {data: 'source'}
      {data: 'platform'}
      {data: 'dispute'}
#      {data: 'last_name'}
#      {data: 'email'}
#      {data: 'bio'}
    ]