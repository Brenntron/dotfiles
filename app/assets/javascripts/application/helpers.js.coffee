namespace 'AC.Helpers', (exports) ->

  exports.populateDropdown = (text_value, element) ->
    i = 0
    while i < element.options.length
      if element.options[i].text == text_value
        element.selectedIndex = i
        break
      i++
    return
