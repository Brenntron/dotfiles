/**
 * Created by mtaylor on 2/6/18.
 */
$(document).ready(function() {
    /* Using 'tooltipped' class instead of 'tooltip' so that it doesn't interfere with Bootstrap */
    $('.tooltipped').tooltipster({
        theme: ['tooltipster-borderless', 'tooltipster-borderless-customized']
    });

    $('.tooltip-alert').tooltipster({
        theme: ['tooltipster-default', 'tooltipster-default-alert'],
        interactive: true,
        side: 'bottom'
    });

    $('.tooltip-status').tooltipster({
        theme: ['tooltipster-default', 'tooltipster-default-status'],
        interactive: true,
        side: 'bottom'
    });


});
