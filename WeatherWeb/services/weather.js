// Weather Service

var database = null;
var config = null;

function startService(cfg, db)
{
    console.log("Start WeatherView service");
    database = db;
    config = cfg;
}
function stopService()
{
    
}
function viewService(req, res)
{
    database.query(
        "SELECT measure_date, pressure, latitude, longitude, altitude " +
        "FROM weather_data " +
        "ORDER BY measure_date DESC " +
        "LIMIT 10",
        [],
        function(err, result)
        {
            if (err)
            {
                console.log("Failed to read weather data: ", err);
                return;
            }

            var table = '';
            for (var a in result.rows)
            {
                table += '<tr><td>' + result.rows[a]['measure_date'] + '</td>';
                table += '<td>' + result.rows[a]['latitude'] + '</td>';
                table += '<td>' + result.rows[a]['longitude'] + '</td>';
                table += '<td>' + result.rows[a]['altitude'] + '</td>';
                table += '<td>' + result.rows[a]['pressure'] + '</td></tr>';
            }

            res.send(
                '<!DOCTYPE html>' +
                '<html lang="en">' +
                '<head>' +
                    '<title>Weather Near You</title>' +
                    '<meta charset="utf-8">' +
                    '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">' +
                    '<meta http-equiv="X-UA-Compatible" content="IE=edge">' +
                    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
                    '<link rel="stylesheet" href="/assets/style.css">' +
                    '<script data-cfasync="false" src="/assets/scripts.js"></script>' +
                '</head>' +
                '<body>' +
                    '<section class="content">' +
                        '<table>' +
                            '<thead><tr><th>Time</th><th>Latitude</th><th>Longitude</th><th>Altitude</th><th>Pressure</th></tr></thead>' +
                            '<tbody>' + table + '</tbody>' +
                        '</table>' +
                    '</section>' +
                '</body>' +
                '</html>'
            );
        }
    );
}

module.exports = {
    start : startService,
    stop : stopService,
    view : viewService
};
