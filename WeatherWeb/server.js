var express = require('express');
var app = express();
var server = require('http').Server(app);
var io = require('socket.io')(server);
var fs = require('fs');
var pg = require('pg');

var weather = require('./services/weather.js');

// Load config

var config = {};
if (fs.existsSync('config.json')) {
    var configStr = fs.readFileSync('config.json');
    try {
        config = JSON.parse(configStr);
    } catch (e) {
        console.log('Failed to parse a config file', e.message)
        process.exit(0);
    }
} else {
    console.log('No config.json found');
    process.exit(0);
}

// Start HTTP server

console.log("Start server on: " + config['http_port']);
server.listen(config['http_port']);

// Connect database

console.log("Connect to: " + config['psql_url']);
const client = new pg.Client(config['psql_url']);
client.connect(function(err)
{
    if (err)
    {
        done();
        console.log(err);
        return;
    }
    startServices(client);
});

// Start services

function startServices(db)
{
    console.log("Starting services");

    weather.start(config, db);

    app.use(express.static('public'))
    app.get('/', weather.view);
}

