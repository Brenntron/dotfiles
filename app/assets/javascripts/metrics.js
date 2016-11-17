
$(document).ready(function() {
    if ($('.user-metrics').length > 0) {
        var user_id = $('.user-metrics')[0].id;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: user_id + '/status_metrics',
            dataType: 'json',
            success: function (data) {
                status_draw(data);
                debugger
            },
            error: function (result) {
                $('#msg').html("<div class='alert alert-danger'>Something went wrong loading the status metrics.</div>");
            }
        });
    };
});

function status_draw(data) {
    var ctx = document.getElementById("statusChart");
    debugger;
    var myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: Object.keys(data.users[0]),
            datasets: [{
                label: "Pending",
                lineTension: 0.1,
                borderCapStyle: 'butt',
                backgroundColor: 'rgba(54, 162, 235, 0.2)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderJoinStyle: 'miter',
                borderWidth: 2,
                pointBorderColor: 'rgba(54, 162, 235, 1)',
                pointBackgroundColor: 'rgba(54, 162, 235, 1)',
                pointBorderWidth: 1,
                pointHoverRadius: 3,
                pointHoverBackgroundColor: 'rgba(54, 162, 235, 0.2)',
                pointHoverBorderColor: 'rgba(54, 162, 235, 1)',
                pointHoverBorderWidth: 1,
                pointRadius: 1,
                pointHitRadius: 10,
                data: create_array(data.users[0])
            }, {
                label: "Reopened",
                lineTension: 0.1,
                borderCapStyle: 'butt',
                backgroundColor: 'rgba(255, 99, 132, 0.2)',
                borderColor: 'rgba(255,99,132,1)',
                borderJoinStyle: 'miter',
                borderWidth: 2,
                pointBorderColor: 'rgba(255,99,132,1)',
                pointBackgroundColor: 'rgba(255,99,132,1)',
                pointBorderWidth: 1,
                pointHoverRadius: 3,
                pointHoverBackgroundColor: 'rgba(255, 99, 132, 0.2)',
                pointHoverBorderColor: 'rgba(255,99,132,1)',
                pointHoverBorderWidth: 1,
                pointRadius: 1,
                pointHitRadius: 10,
                data: create_array(data.users[1])
            }]
        },
        options: {
            legend: {
                display: true
            },
            tooltips: {
                y: "String",
                titleSpacing: 3
            },
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        stepSize: 2
                    },
                    scaleLabel: {
                        display: true,
                        labelString: 'Bug Count'
                    },
                    gridLines: {
                        display:false
                    }
                }],
                xAxes: [{
                    gridLines: {
                        display:false
                    }
                }]
            }
        }
    });
};

$(document).ready(function() {
    if ($('.user-metrics').length > 0) {
        var user_id = $('.user-metrics')[0].id;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: user_id + '/time_metrics',
            dataType: 'json',
            success: function (data) {
                time_draw(data);
            },
            error: function (result) {
                $('#msg').html("<div class='alert alert-danger'>Something went wrong loading the work time metrics.</div>");
            }
        });
    };
});

function time_draw(data) {
    var ctx = document.getElementById("timeChart");
    var myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ["Work Time", "Re-work Time", "Review Time", "Resolution Time"],
            datasets: [{
                data: data.users,
                backgroundColor: [
                    'rgba(255, 206, 86, 0.2)',
                    'rgba(75, 192, 192, 0.2)',
                    'rgba(153, 102, 255, 0.2)',
                    'rgba(255, 159, 64, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)',
                    'rgba(153, 102, 255, 1)',
                    'rgba(255, 159, 64, 1)'
                ],
                borderWidth: 1
            }]
        },
        options: {
            legend: {
                display: false
            },
            tooltips: {
                callbacks: {
                    label: function (tooltipItem, data) {
                        if (tooltipItem.xLabel == 'Work Time') {
                            return "Time between assignment and being set to pending."
                        }
                        else if (tooltipItem.xLabel == 'Re-work Time') {
                            return "Time between reopen and being set back to pending."
                        }
                        else if (tooltipItem.xLabel == 'Review Time') {
                            return "Time between being set to pending and resolved."
                        }
                        else if (tooltipItem.xLabel == 'Resolution Time') {
                            return "Time between bug creation and resolution."
                        }
                        else {
                            return tooltipItem.xLabel;
                        }
                    }
                },
            },
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        stepSize: 2,
                        max: Math.max.apply(null, data.users) + 2
                    },
                    scaleLabel: {
                        display: true,
                        labelString: 'Average Number of Days *'
                    },
                    gridLines: {
                        display:false
                    }
                }],
                xAxes: [{
                    gridLines: {
                        display:false
                    }
                }]
            }
        }
    });
};

function create_array(data) {
    array = [];
    $.each( data, function( key, value ) {
        array.push(value);
    });
    return array;
}


