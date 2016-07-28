$ ->
  $(document).on 'click','.rules_check_box', ->
    $(".rule_check_box").prop("checked", $(".rules_check_box").prop("checked"))

  $(document).on 'click','.rules_check_box, .rule_check_box', ->
    selected = []
    allboxes = []
    $('input:checkbox.rule_check_box').each ->
      allboxes.push($(this).val())
      if @checked
        _val = $(this).val()
        selected.push(_val)
    allboxes = $.unique(allboxes)
    $.each allboxes, (i, v) ->
      $('.rule_'+v).removeClass('active').addClass('hidden')
    $.each selected, (i, v) ->
      $('.rule_'+v).removeClass('hidden').addClass('active')

  $(document).on 'click', '#remove',  ->
    alert('Selected rules will be removed. Are you sure?')
    selected = []
    $('input:checkbox.rule_check_box').each ->
      if @checked
       selected.push($(this).val())
    $.ajax {
      url: "/rules"
      data: { ids: selected }
      type: 'DELETE'
      dataType: 'json'
      success: (response) ->
        $.each selected, (index, value) ->
          $('.rules_table tr#'+value).remove()
      error: (response) ->
        console.log('Error')
    }


