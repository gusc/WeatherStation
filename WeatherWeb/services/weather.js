// SMS Service

var request = require('request');

var smsTimeout = null;
var database = null;
var config = null;

function startService(cfg, db)
{
    console.log("Start WeatherView service");
    database = db;
    config = cfg;
}
function finishService()
{
    
}
function viewService(req, res)
{
    
}

module.exports = {
    start : startService,
    stop : stopService,
    view : viewService
};
