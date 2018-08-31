var system = require('system');
var url = system.args[1];
var filename = system.args[2];
var page = new WebPage();


page.open(url, function (status) {
  page.render(filename);
  console.log(filename);
  phantom.exit();
});