CREATE TABLE weather_data (
    id serial NOT NULL,
    measure_date timestamp DEFAULT now(),
    pressure real,
    temperature real,
    latitude real NOT NULL,
    longitude real NOT NULL,
    altitude real NOT NULL,
    PRIMARY KEY (id)
);
