# Disclaimer

This project is a prototype for demo purposes as part of the final project of the Executive Master of Data Science (2020) of the [MBIT School](https://www.mbitschool.com/). 


***It is not inteended to be run in a production environment.***

There are 2 python applications:
1. model_api: a Flask application with a rest API for executing predictions.
2. demo_app: a Dash application that collects few inputs and calls the api REST for predicting excursions, It display to top 5 predicted excursions.  

### Requirements
You need to install python3. Check the list of imports in the *.py* files for installing the rest of libraries.

For Flask you can follow the instructions at https://pypi.org/project/Flask/

For installing Dash:  https://dash.plotly.com/installation


# 1. model_api

The model_api is a Flask application that implements some rest APIs. It allows to make API call to a predict method for executing predictions of the model.

## Project organization
The project is organized as follows:
```
model_api
  /config
  /data
  /logs
  /models
  app.py
```
**/config**
It contains the configuration file.

**/data**
It contains a csv with the excursion metadata.

**/logs**
It contains some log files having trace for the execution of the prediction API. You can leave this folder empty and you need to remember 

**/models**
It contains the pickle files for different models. The model to be used is set in the config file.

**app.py**:  The main program file

## Basic configuration
```
app.config

{
    "_comment" : "This is the configuration file for the app.py",
    "model":"et_turbo_0.8813.pkl",
    "aemet":{
        "municipio":"38038",
        "url":"https://opendata.aemet.es/opendata",
        "api_key":"set your own key amiguito"
    }
}
```

The main settings to configure are:
- model: the pickle filename of the predictor model. it must be in the folder /models.
- aemet.municipio: the municipality to get the weather forecast of. 38038 is for Tenerife.
- aemet.url: the url of the Open Data AEMET.
- aemet.api_key: the api key for using the Open Data AEMET.

For details on using the AEMET Open data: https://opendata.aemet.es/

### Logging configuration
```
app._pylog.config
```
The application uses the python logging library. For details or changes of the configuration you can check the python documentation at https://docs.python.org/3/howto/logging.html 

## APIs
```
/GET reload
```
Allows to reload the configuration file without restarting the service.

```
/GET forecast/:date
```
Returns the forecast prediction for Santa Cruz de Tenerife for the selected date.

URI parameters:
:date in format YYYY-MM-DD and limited to [today, today+6 days] only.

Example:
```
/GET forescast/25-11-2021
200
{
  "date": "2021-11-25T00:00:00", 
  "rain_prob": 100, 
  "rain_prob_timestamp": "00-24", 
  "temp_max": 22, 
  "wind_dir": "E", 
  "wind_dir_timestamp": "00-24", 
  "wind_vel": 4.17
}
```
```
/POST predict
```
Returns a list of excursions ordered by its prediction’s probability.
```
/POST predict
{
  "excursion_date":"2021-11-25",
  "lead_pax_age":45,
  "adt":2,
  "chd":0,
  "inf":0,
  "price_per_pax":150
}
200
[
    {
        "STOCK_CODE":"PESTCI4HYS",
        "proba":0.994,
        "STOCK_NAME":"Gomera Safari Tour "
    },
    {
        "STOCK_CODE":"XESTCI9VN2",
        "proba":0.006,
        "STOCK_NAME":"Teide By Night And Romantic Tour Only For Adults "
    },
    {
        "STOCK_CODE":"XESTCIB26U",
        "proba":0.0,
        "STOCK_NAME":"Flipper Uno"
    },
    {
        "STOCK_CODE":"XESTCIBSBI",
        "proba":0.0,
        "STOCK_NAME":"Mts. Teide South"
    },
    { …
    } 
]
```



# 2. demo_app

The main code for the webapp is in the file dashapp.py

It creates a simple web UI form for collecting the minimum input for the user that will be used for building the feature’s array that the prediction model uses as a input.
It makes a call to the model’s API and displays the top 5 excursions ordered by its prediction probability.

Project organization:
```
/demo_app
  /assets
dashapp.py
```

**/assets**
It contains a css file for nicer design.

**dashapp.py**:  The main program file


