# Disclaimer

This project is a prototype for demo purposes. 

***It is not inteended to be run in a production environment.***


# model_api

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


# demo_app

