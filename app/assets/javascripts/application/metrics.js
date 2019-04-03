Chart.defaults.global.plugins.datalabels.display = false

$(document).ready(function() {
    get_bug_chart_data('bug_metrics');
    get_user_chart_data('status_metrics');
    get_user_chart_data('time_metrics');
    get_manager_chart_data('pending_team_metrics');
    get_manager_chart_data('resolved_team_metrics');
    get_manager_chart_data('time_team_metrics');
    get_manager_chart_data('component_team_metrics');
});

//bug metrics
function get_bug_chart_data(url) {
    if ($('.bug-metrics').length > 0) {
        var bug_id = $('.bug-metrics')[0].id;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: bug_id + '/' + url,
            dataType: 'json',
            success: function (data) {
                bug_draw(data);
            },
            error: function (result) {
                $('#msg').html("<div class='alert alert-danger'>Something went wrong loading the metrics.</div>");
            }
        });
    }
}

//users metrics
function get_user_chart_data(url) {
    if ($('.user-metrics').length > 0) {
        var user_id = $('.user-metrics')[0].id;
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: user_id + '/' + url,
            dataType: 'json',
            success: function (data) {
                if (url == 'status_metrics') {
                    status_draw(data);
                }
                else if (url == 'time_metrics') {
                    time_draw(data);
                }
            },
            error: function (result) {
                $('#msg').html("<div class='alert alert-danger'>Something went wrong loading the metrics.</div>");
            }
        });
    }

}

//managers metrics
function get_manager_chart_data(url) {
    if ($('.user-metrics-manager').length > 0) {
        $.ajax({
            type: "GET",
            contentType: "application/json; charset=utf-8",
            url: url,
            dataType: 'json',
            success: function (data) {
                if (url == 'pending_team_metrics') {
                    status_team_draw(data,'pending','line');
                }
                else if (url == 'resolved_team_metrics') {
                    status_team_draw(data,'resolved','line');
                }
                else if (url == 'time_team_metrics') {
                    team_work_time_draw(data, "worktimeChart")
                }
                else if (url == 'component_team_metrics') {
                    team_work_time_draw(data, "componenttimeChart")
                }
            },
            error: function (result) {
                $('#msg').html("<div class='alert alert-danger'>Something went wrong loading the work time metrics.</div>");
            }
        });
    }
}

//bug view charts

function bug_draw(data) {
    var ctx = document.getElementById("bugChart");
    var myChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ["Work Time", "Re-work Time", "Review Time", "Resolution Time"],
            datasets: [{
                label: "Number of Days",
                data: data,
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
                position: 'right',
                labels: {
                    usePointStyle: true
                }
            },
            tooltips: {
                callbacks: {
                    title: function (tooltipItem, data) {
                        // debugger
                        if (data['labels'][tooltipItem[0]['index']] == 'Work Time') {
                            return "Time between assignment and being set to pending."
                        }
                        else if (data['labels'][tooltipItem[0]['index']] == 'Re-work Time') {
                            return "Time between reopen and being set back to pending."
                        }
                        else if (data['labels'][tooltipItem[0]['index']] == 'Review Time') {
                            return "Time between being set to pending and resolved."
                        }
                        else if (data['labels'][tooltipItem[0]['index']] == 'Resolution Time') {
                            return "Time between bug creation and resolution."
                        }
                        else {
                            return data['labels'][tooltipItem[0]['index']];
                        }
                    },
                    label: function (tooltipItem, data) {
                        return 'Days: ' + data['datasets'][0]['data'][tooltipItem['index']]
                    }
                }
            }
        }
    });
}



//users view charts
function status_draw(data) {
    var ctx = document.getElementById("statusChart");
    var myChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: Object.keys(data[0]),
            datasets: [{
                label: "Pending",
                lineTension: 0.1,
                borderCapStyle: 'butt',
                backgroundColor: 'rgba(54, 162, 235, 0.2)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderJoinStyle: 'miter',
                borderWidth: 1,
                pointBorderColor: 'rgba(54, 162, 235, 1)',
                pointBackgroundColor: 'rgba(54, 162, 235, 1)',
                pointBorderWidth: 1,
                pointHoverRadius: 3,
                pointHoverBackgroundColor: 'rgba(54, 162, 235, 0.2)',
                pointHoverBorderColor: 'rgba(54, 162, 235, 1)',
                pointHoverBorderWidth: 1,
                pointRadius: 1,
                pointHitRadius: 10,
                data: create_array(data[0])
            }, {
                label: "Reopened",
                lineTension: 0.1,
                borderCapStyle: 'butt',
                backgroundColor: 'rgba(255, 99, 132, 0.2)',
                borderColor: 'rgba(255,99,132,1)',
                borderJoinStyle: 'miter',
                borderWidth: 1,
                pointBorderColor: 'rgba(255,99,132,1)',
                pointBackgroundColor: 'rgba(255,99,132,1)',
                pointBorderWidth: 1,
                pointHoverRadius: 3,
                pointHoverBackgroundColor: 'rgba(255, 99, 132, 0.2)',
                pointHoverBorderColor: 'rgba(255,99,132,1)',
                pointHoverBorderWidth: 1,
                pointRadius: 1,
                pointHitRadius: 10,
                data: create_array(data[1])
            }]
        },
        options: {
            legend: {
                display: true,
                position: 'right',
                labels: {
                    usePointStyle: true
                }
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

function time_draw(data) {
    var ctx = document.getElementById("timeChart");
    var myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ["Work Time", "Re-work Time", "Review Time"],
            datasets: [{
                data: data,
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
                    title: function (tooltipItem, data) {
                        if (tooltipItem[0].xLabel == 'Work Time') {
                            return "Time between assignment and being set to pending."
                        }
                        else if (tooltipItem[0].xLabel == 'Re-work Time') {
                            return "Time between reopen and being set back to pending."
                        }
                        else if (tooltipItem[0].xLabel == 'Review Time') {
                            return "Time between being set to pending and resolved."
                        }
                        else {
                            return tooltipItem[0].xLabel;
                        }
                    },
                    label: function (tooltipItem, data) {
                        return 'Days: ' + tooltipItem.yLabel
                    }
                },
            },
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
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
}

//managers view charts
function status_team_draw(data, status, type) {
    var ctx = document.getElementById(status + "Chart");
    var myChart = new Chart(ctx, {
        type: type,
        data: {
            labels: create_label_hash(data),
            datasets: create_data_hash(data)
        },
        options: {
            legend: {
                display: true,
                position: 'right',
                labels: {
                    usePointStyle: true
                }
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
}

function team_work_time_draw(data, id) {
    var ctx = document.getElementById(id);
    var myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ["Work Time", "Re-work Time", "Review Time"],
            datasets: create_work_time_data_hash(data)
        },
        options: {
            legend: {
                display: true,
                position: 'right',
                labels: {
                    usePointStyle: true
                }
            },
            tooltips: {
                callbacks: {
                    title: function (tooltipItem, data) {
                        if (tooltipItem[0].xLabel == 'Work Time') {
                            return "Time between assignment and being set to pending."
                        }
                        else if (tooltipItem[0].xLabel == 'Re-work Time') {
                            return "Time between reopen and being set back to pending."
                        }
                        else if (tooltipItem[0].xLabel == 'Review Time') {
                            return "Time between being set to pending and resolved."
                        }
                        else {
                            return tooltipItem[0].xLabel;
                        }
                    }
                },
            },
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
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
}

// helper functions

function create_array(data) {
    array = [];
    $.each( data, function( key, value ) {
        array.push(value);
    });
    return array;
}

function create_data_hash(data) {
    var hash = [];
    colorCount = 0;
    for (var i = 0; i < Object.keys(data).length; i++) {
        color = generate_color();
        hash[i] = {
            label: Object.keys(data[i]),
            data: create_array(create_array(data[i])[0]),
            lineTension: 0.1,
            borderCapStyle: 'butt',
            backgroundColor: color[colorCount][0],
            borderColor: color[colorCount][1],
            borderJoinStyle: 'miter',
            borderWidth: 1,
            pointBorderColor: color[colorCount][1],
            pointBackgroundColor: color[colorCount][0],
            pointBorderWidth: 1,
            pointHoverRadius: 3,
            pointHoverBackgroundColor: color[colorCount][0],
            pointHoverBorderColor: color[colorCount][1],
            pointHoverBorderWidth: 1,
            pointRadius: 1,
            pointHitRadius: 10
        };
        if(colorCount == color.length - 1) {
            colorCount = 0;
        }
        else{
            colorCount += 1
        }
    }
    return hash;
}


function create_work_time_data_hash(data) {
    var hash = [];
    colorCount = 0;
    for (var i = 0; i < data.length; i++) {
        color = generate_color();
        hash[i] = {
            label: Object.keys(data[i]),
            data: create_array(data[i])[0],
            backgroundColor: color[colorCount][0],
            borderColor: color[colorCount][1],
            borderWidth: 1
        };
        if(colorCount == color.length - 1) {
            colorCount = 0;
        }
        else{
            colorCount += 1
        }
    }
    return hash;
}

function create_label_hash(data) {
    var array = [];
    var label = Object.keys(data[0]);
    array.push(Object.keys(data[0][label]));
    return array[0];
}

function generate_color() {
    return color_array = [
        ['rgba(255, 99, 132, 0.2)', 'rgba(255,99,132,1)'],
        ['rgba(54, 162, 235, 0.2)', 'rgba(54, 162, 235, 1)'],
        ['rgba(255, 206, 86, 0.2)','rgba(255, 206, 86, 1)' ],
        ['rgba(75, 192, 192, 0.2)', 'rgba(75, 192, 192, 1)'],
        ['rgba(153, 102, 255, 0.2)', 'rgba(153, 102, 255, 1)'],
        ['rgba(255, 159, 64, 0.2)', 'rgba(255, 159, 64, 1)'],
        ['rgba(179, 181, 198, 0.2)','rgba(179,181,198,1)' ]

    ];

}


