$(document).ready(function() {

    $('.active').show();
    $('.hidden').hide();

    $(function () {
        $('#myTab a:first').tab('show');
    });

    $('.rules').click(function () {
        var tab = $(this).attr("id");
        if(tab!="remove" && tab!="test") {
            $('.row.active').addClass('hidden').removeClass('active');
            $('.' + tab).addClass('active').removeClass('hidden');
        }
        $('.active').show();
        $('.hidden').hide();
    });

    $('#change_summary').click(function () {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('input[name="id"]').val();
        var summary = $('input[name="summary"]').val();
        $.ajax({
            url: "/bugs/" + id,
            method: 'PUT',
            data: {'bug': {'summary': summary}},
            headers: headers
        }).done(function (response) {
            $('.bug_summary').html(response.bug.summary);
        });
    });

    $('document').on('click', '#add_reference', function () {
        var headers = {'Token': $('input[name="token"]').val(), 'Xmlrpc-Token': $('input[name="xml_token"]').val()};
        var id = $('input[name="id"]').val();
        var reference = $('#reference-bugs-type').val();
        var content = $('input[name="content"]').val();
        $.ajax({
            url: "/bugs/" + id + "/references",
            method: 'POST',
            data: {reference: {'reference_data': content, 'reference_type_id': reference}},
            headers: headers
        }).done(function (response) {
            console.log(response);
            alert('success');
        });
    });


    $(document).on('click', '.connection', function () {
        if ($('#scratch_connection').prop("checked")) {
            $('#scratch_connection_text').prop('disabled', false);
        } else {
            $('#scratch_connection_text').prop('disabled', true);
        }
        ;
    });
    $('.flow').click(function () {
        if ($('#scratch_flow').prop("checked")) {
            $('#scratch_flow_text').prop('disabled', false);
        } else {
            $('#scratch_flow_text').prop('disabled', true);
        }
        ;
    });
    $('.metadata').click(function () {
        if ($('#scratch_metadata').prop("checked")) {
            $('#scratch_metadata_text').prop('disabled', false);
        } else {
            $('#scratch_metadata_text').prop('disabled', true);
        }
        ;
    });

});
