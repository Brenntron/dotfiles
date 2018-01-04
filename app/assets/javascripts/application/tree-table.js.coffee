$ ->
  table = $('#tree-table')
  rows = table.find('tr')

  rows.each (index, row) ->
    row = $(row)
    level = row.data('level')
    id = row.data('id')
    columnName = row.find('td[data-column="name"]')
    children = table.find('tr[data-parent="' + id + '"]')

    if children.length
      expander = columnName.prepend('' + '<span class="treegrid-expander glyphicon glyphicon-chevron-right"></span>' + '')
      children.hide()
      expander.on 'click', (e) ->
        target = $(e.target)
        if target.hasClass('glyphicon-chevron-right')
          target.removeClass('glyphicon-chevron-right').addClass 'glyphicon-chevron-down'
          children.show()
        else
          target.removeClass('glyphicon-chevron-down').addClass 'glyphicon-chevron-right'
          reverseHide table, row
        cleanUp()
        return
    columnName.prepend '' + '<span class="treegrid-indent" style="padding-left:' + 15 * level + 'px"></span>' + ''
    return

  # Reverse hide all elements

  reverseHide = (table, element) ->
    element = $(element)
    id = element.data('id')
    children = table.find('tr[data-parent="' + id + '"]')
    if children.length
      children.each (i, e) ->
        reverseHide table, e
        return
      element.find('.glyphicon-chevron-down').removeClass('glyphicon-chevron-down').addClass 'glyphicon-chevron-right'
      children.hide()
    return

  cleanUp = ->
    $('td.glyphicon-chevron-right').removeClass 'glyphicon-chevron-right'
    $('td.glyphicon-chevron-down').removeClass 'glyphicon-chevron-down'
    $('.treegrid-indent.glyphicon-chevron-right').removeClass 'glyphicon-chevron-right'


  return
