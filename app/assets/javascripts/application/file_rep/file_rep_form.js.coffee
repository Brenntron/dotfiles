# WIP for this coffee file
# this file will pass the SHAs to the back-end
$ ->

  $('#new-file-rep-form').on 'submit', (e) ->
    e.preventDefault()

    shas_input_type = $('#shas_input_type').val()
    shas_full_text = $('#shas_list').val()
    disposition = $('#disposition_suggested').val()
    assignee = $('#assignee').val()

    shas_array = shas_full_text.split(/[\s,;]+/)

    i = undefined
    curr_sha_object = {}
    regexp = /^[0-9A-Fa-f]+$/

    if shas_array
      console.log '# OF SHA(s): \n' + shas_array.length + '\n'

      while i < shas_array.length
        if shas_array[i] == ''
          continue

        else if regexp.test(shas_array[i])

          # build this in back-end, this block below should probably be deleted
          curr_sha_object =
            sha: shas_array[i]
            disposition_suggested: disposition
            assignee: assignee
          regexp.lastIndex = 0

          console.log curr_sha_object

        else if regexp.test(shas_array[i] == false)

          regexp.lastIndex = 0
          console.log 'this sha is BAD: ' + shas_array[i + '\n']

        else
          console.log 'Unknown error occured. Please try again.'

    else
      alert 'Hi there, please enter some SHAs to continue.'

    return
return

