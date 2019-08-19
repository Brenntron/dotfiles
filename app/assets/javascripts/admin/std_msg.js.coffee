
window.std_msg_set_class =(new_class, selector = '#api-msg') ->
  api_msg = $(selector)[0]
  if api_msg
    api_msg.classList.remove('hidden-msg')
    api_msg.classList.remove('success-msg')
    api_msg.classList.remove('error-msg')
    api_msg.classList.remove('fail-msg')
    api_msg.classList.add(new_class)


window.array_to_ul =(items) ->
  list = []
  for item in items
    list.push('<li>' + item + '</li>')
  '<ul>' + list.join("\n") + '</ul>'


window.std_msg_set =(banner, messages) ->
  msg_div = $('#api-msg').find('#message-text')[0]
  if undefined == banner
    $(msg_div).html('')
  else
    $(msg_div).html(banner + array_to_ul(messages))


window.std_msg =(banner, messages, options = {}) ->
  if undefined == banner
    if options.reload == true
      location.reload(true)
    else if undefined != options.complete
      options.complete()
  else
    std_msg_set(banner, messages)

    if options.reload == true
      $('#msg-modal').on('hidden.bs.modal', ->
        location.reload(true)
        $('#msg-modal').on('hidden.bs.modal', -> { })
      )
    else if undefined != options.complete
      $('#msg-modal').on('hidden.bs.modal', ->
        options.complete()
        $('#msg-modal').on('hidden.bs.modal', -> { })
      )

    $('#msg-modal').modal('show')


# standard function to display a success message.
# @param [string] banner message to display at top.
# @param [Array[string]] messages array of lines to display in the message.
# @param [Hash] options set complete: to a function to call after message is dismissed
window.std_msg_success =(banner, messages, options = {}) ->
  std_msg_set_class('success-msg', '#api-msg')
  std_msg(banner, messages, options)


# standard function to display an error message.
# @param [string] banner message to display at top.
# @param [Array[string]] messages array of lines to display in the message.
# @param [Hash] options set complete: to a function to call after message is dismissed
window.std_msg_error =(banner, messages, options = {}) ->
  std_msg_set_class('error-msg', '#api-msg')
  std_msg(banner, messages, options)


# standard function to display an error message.
# @param [string] banner message to display at top.
# @param [Array[string]] messages array of lines to display in the message.
# @param [Hash] options set confirm: to a function to call after message is dismissed
window.std_msg_confirm =(banner, messages, options = {}) ->
  std_msg_set_class('error-msg', '#api-msg')
  std_msg_set(banner, messages)

  if options.reload == true
    $('.confirm').click ->
      location.reload(true)
      $('.confirm').click ->
  else if undefined != options.confirm
    $('.confirm').click ->
      $('.confirmation-buttons').addClass('hidden')
      options.confirm()
      if options.success_msg != undefined
        std_msg_success(options.success_msg, success_reload: options.success_reload)
      else if false == options.confirm_dismisss || undefined == options.confirm_dismiss
        $('#msg-modal').modal('hide')
      $('.confirm').click ->

  $('.confirmation-buttons').removeClass 'hidden'
  $('#msg-modal').modal('show')


window.std_msg_no_rule_selected =() ->
  std_msg_error('No rule selected', ['Please select at least one rule.'])


# standard way to call AJAX, supporting a confirmation message.
# @param [Hash] ajax_data data and options for this AJAX call.
window.std_msg_ajax =(ajax_data) ->
  if undefined == ajax_data.confirm_banner
    std_api_ajax(ajax_data)
  else
    std_msg_confirm(
      ajax_data.confirm_banner,
      ajax_data.confirm_messages,
      {
        confirm_dismiss: false,
        confirm: ->
          std_api_ajax(ajax_data)
      }
    )
