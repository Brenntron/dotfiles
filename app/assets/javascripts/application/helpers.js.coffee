namespace 'AC.Helpers', (exports) ->

  exports.populateDropdown = (text_value, element) ->
    i = 0
    while i < element.options.length
      if element.options[i].text == text_value
        element.selectedIndex = i
        break
      i++
    return


  exports.clipboard = ->

    $(document).ready ->
      clipboard = new Clipboard('.clipboard-btn')
      clipboard.on 'success', (e) ->
        setTooltip e.trigger, 'Copied!'
        hideTooltip e.trigger
        return
      clipboard.on 'error', (e) ->
        setTooltip e.trigger, 'Failed!'
        hideTooltip e.trigger
        return
      return

    $('.clipboard-btn').tooltip
      trigger: 'click'
      placement: 'bottom'

  setTooltip = (btn, message) ->
    $(btn).tooltip('hide').attr('data-original-title', message).tooltip 'show'
    return

  hideTooltip = (btn) ->
    setTimeout (->
      $(btn).tooltip 'hide'
      return
    ), 1000
    return
