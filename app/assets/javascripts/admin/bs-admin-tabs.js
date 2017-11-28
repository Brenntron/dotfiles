/**
 * Created by mtaylor on 11/28/17.
 */
$(document).ready( function() {
    $('#admin-rules-tabs a').on('click', function (e) {
        e.preventDefault()
        $(this).tab('show')
    });
});
