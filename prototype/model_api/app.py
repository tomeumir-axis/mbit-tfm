#
# MBIT School - Executive master in Data Science (2020-2021)
#
# Date:
#   November, 2021
# Authors: 
#   Nuria Espadas
#   Mireia Vecino
#   Tomeu Mir
#
# app.py : A Flask prototype for the Predictive Model selected 
#
#
import os
import pandas as pd
from flask import Flask, jsonify, request
import requests
import json
import pickle
import datetime
import random
import logging
import logging.config

pd.set_option('max_columns', None)

# setting the working paths based on the local path were the executable python file is located
os.chdir(os.path.dirname(os.path.realpath(__file__)))
localpath = os.getcwd()
CONFIG_PATH = localpath+'/config/' 
DATA_PATH = localpath+'/data/'
MODEL_PATH = localpath+'/models/'

# Initialation of the logging
logging.config.fileConfig(CONFIG_PATH+'app_pylog.config')
logging.info('STARTING...')

# Globals
df_ranking = None
model = None
aemet = {}

# load settings from the config file
def load_settings():
    logging.info('Loading configurations...')
    global df_ranking
    global model
    global aemet

    #Load configurations for AEMET API
    with open( CONFIG_PATH+'app.config') as f:
        settings = json.load( f)
    aemet['municipio'] = settings['aemet']['municipio']
    aemet['url'] = settings['aemet']['url']
    aemet['api_key'] = settings['aemet']['api_key']
    #load model
    logging.info('model to load:'+MODEL_PATH+settings['model'])
    model = pickle.load(open(MODEL_PATH+settings['model'],'rb'))
    logging.info('model loaded')
    #load ranking of excursions (as a metadata for having the code and the name)
    df_ranking = pd.read_csv(DATA_PATH+'df_ranking.csv')
    df_ranking.drop( ['Unnamed: 0','total'], axis=1, inplace=True)
    logging.info('Excursions metadata loaded')
    logging.info('Configurations loaded')

load_settings()

def transationId():
    # returns a unique transaction id based on a random hash
    return str(random.getrandbits(32))


# init Flask file
app = Flask(__name__)


# API rest: /Get reload
# reloads the configuration without interrupting the service
@app.route('/reload',methods=['GET'])
def reload( ):
    load_settings()
    item = {'Reload':'ok', 'time':datetime.datetime.now()}
    return jsonify(item)

# API rest : /GET forecat
# connects to the AEMET API and returns the weather forecast for the especified date in the URL
@app.route('/forecast/<excursion_date>',methods=['GET'])
def forecast( excursion_date):
    # get prediction from AEMET opendata
    url = aemet['url']
    api_key = aemet['api_key']
    api = '/api/prediccion/especifica/municipio/diaria/'+aemet['municipio']
    response = requests.request("GET", url+api, headers={'cache-control': "no-cache"}, params={"api_key":api_key})
    # print(response.text)
    if response.status_code != 200:
        return response
    
    js =  json.loads(response.text)
    datos = requests.request("GET", js['datos'])
    forecast = json.loads(datos.text)
    
    item = {}
    for f in forecast[0]['prediccion']['dia']:
        if excursion_date in f['fecha']:
            # build output.
            item['date'] = f['fecha']
            item['temp_max'] = f['temperatura']['maxima']
            item['wind_dir'] = f['viento'][0]['direccion']
            if 'periodo' in f['viento'][0]:
                item['wind_dir_timestamp'] = f['viento'][0]['periodo']
            else:
                item['wind_dir_timestamp'] = 'NaN'
            viento_kmh = f['viento'][0]['velocidad']
            item['wind_vel'] = round(viento_kmh * 1000/3600,2)
            item['rain_prob'] = f['probPrecipitacion'][0]['value']
            if 'periodo' in f['probPrecipitacion'][0]:
                item['rain_prob_timestamp'] = f['probPrecipitacion'][0]['periodo']
            else:
                item['rain_prob_timestamp'] = 'NaN'

    return jsonify(item)



# API rest : /POST predict
# returns a list of excursions ordered by the prediction probability
# it uses the model loaded using pickle
'''
body document example: 
    {
    'excursion_date':'2021-11-20',
    'lead_pax_age':80,
    'adt':2,
    'chd':0,
    'inf':0,
    'price_per_pax':50
    }
 
The rest of the model parameters are automatically generated using the AEMET api.
'''
@app.route('/predict',methods=['POST'])
def predict():
    start_time = datetime.datetime.now()
    # get a new transaction id
    transactionid = transationId()
    logging.info('[%s] NEW prediction',transactionid)
    # get data received in the request body and build some of the model variables
    data = request.get_json(force=True)
    df_data = pd.DataFrame( data, index=[0])
    df_data['excursion_date'] = pd.to_datetime(df_data['excursion_date'])
    df_data['i_start_dayofweek'] = df_data['excursion_date'].dt.dayofweek  # 0-Mon ... 6-Sun
    df_data['booking_date'] = pd.Timestamp('today')
    df_data['i_booking_dayofweek'] = df_data['booking_date'].dt.dayofweek
    df_data['i_days_beforebook'] = abs( df_data['booking_date'].dt.dayofweek - df_data['i_start_dayofweek'])
    logging.info('[%s] form parameters readed',transactionid)
   
    # get meteo data from API
    url = 'http://localhost:5000/forecast/'+ df_data['excursion_date'].astype(str).iloc[0]
    meteo = requests.get(url)
    meteo = meteo.json()
    tmax = meteo['temp_max']
    velmedia = meteo['wind_vel']
    prec = 0 
    # As the api does return only the probability instead of the mm, we will make our own transformations
    # converting the probability to mm (my own invented rules)
    # DISCLAIMER: we should check for a new API for forecasting in a production envrionment.
    rain_prob = meteo['rain_prob']
    if rain_prob < 10:
        sol = random.randint(10, 12)
    elif rain_prob < 60:
        sol = random.randint(8, 9)
    elif rain_prob < 70:
        sol = random.randint(5,8)
    elif rain_prob >= 70:
        sol = random.randint(2,5)
    logging.info('[%s] meteo data received from AEMET',transactionid)

    # prepare model parameters. 
    # model input is:
    # X = [I_DAYSBEFOREBOOK,ADT,CHD,INF,LEAD_PAX_AGE,prec,tmax,velmedia, sol, i_booking_dayofweek, i_start_dayofweek,i_avg_sales]    
    X = [
        df_data['i_days_beforebook'].iloc[0],
        df_data['adt'].iloc[0],
        df_data['chd'].iloc[0],
        df_data['inf'].iloc[0],
        df_data['lead_pax_age'].iloc[0],
        prec,
        tmax,
        velmedia,
        sol,
        df_data['i_booking_dayofweek'].iloc[0],
        df_data['i_start_dayofweek'].iloc[0],
        df_data['price_per_pax'].iloc[0]
    ]
    logging.info('[%s] model input',transactionid)
    logging.info('[%s] '+str(X),transactionid)

    # predict
    Y = 0
    Y = model.predict_proba(pd.DataFrame( X).transpose())
    logging.info('[%s] prediction executed',transactionid)
    
    # build the response
    reco = pd.DataFrame({'STOCK_CODE': list(model.classes_),'proba': Y[0]}).sort_values('proba', ascending = False)
    reco = pd.merge(reco,df_ranking)
    logging.info('[%s] response:',transactionid)
    logging.info('[%s] '+str(reco.to_json(orient='records')),transactionid)
    #print('\nrecommendation list: ')
    #print(reco[:5]) # Top 5
    #print()
    execution_time = round( (datetime.datetime.now() - start_time).total_seconds()*1000)
    logging.info('[%s] execution time (msec): '+str(execution_time),transactionid)


    return reco.to_json(orient='records', indent=4)


# Run server and load APIs
if __name__ == "__main__":
    logging.info('APIs ready!')
    app.run(host="localhost", debug=True)

