# Disclaimer

This project is a prototype for demo purposes as part of the final project of the Executive Master of Data Science (2020) of the MBIT School. 

![image](https://www.mbitschool.com/wp-content/uploads/2020/08/LOGO.png)


***It is not inteended to be run in a production environment.***

There are 2 python applications:
1. model_api: a Flask application with a rest API for executing predictions.
2. demo_app: a Dash application that collects few inputs and calls the api REST for predicting excursions, It display to top 5 predicted excursions.  



# 1. model_api

The model_api is a Flask application that implements some rest APIs. It allows to make API call to a predict method for executing predictions of the model.

## Project organization
The project is organized as follows:

model_api
  /config
  /data
  /logs
  /models
  app.py

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

{
    "_comment" : "This is the configuration file for the app.py",
    "model":"et_turbo_0.8813.pkl",
    "aemet":{
        "municipio":"38038",
        "url":"https://opendata.aemet.es/opendata",
        "api_key":"set your own key amiguito"
    }
}


# demo_app

