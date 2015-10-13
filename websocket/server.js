// This is a server that keeps an eye on activeMQ
// This server can connect to a websocket to publish the changes from activeMQ

var WebSocketServer = require('ws').Server;
var ws = new WebSocketServer({port: 7001});
var Stomp = require('stompjs');
var client = Stomp.overTCP('localhost', 61613);
var app = require('express')();
var http = require('http').Server(app);
var socket = require('socket.io-client')('https://localhost:7000');
socket.on('connect', function(){
  console.log('amq server connected to websocket');
});

var headers = {
  login: 'guest',
  passcode: 'guest'
};
client.connect(headers, function() {
  console.log("Connected to ActiveMQ with Stomp");
  client.subscribe("/queue/RulesUI.Snort.Run.Local.Test.Work", function(message) {
    var data = JSON.parse(message.body);
    publishToWebsocket(JSON.parse(data["record"]));
  });
});

function publishToWebsocket(msg){
  socket.emit('amq', msg);
}