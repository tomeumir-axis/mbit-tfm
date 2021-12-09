
import requests
import pandas as pd

data_form = {
'excursion_date':'2021-11-25',
'lead_pax_age':45,
'adt':2,
'chd':0,
'inf':0,
'price_per_pax':150
}
print( data_form )

url = 'http://localhost:5000/predict'
r = requests.post(url, json=data_form)
print()
print()
print (r.text)
print()
print()


predicted_list = r.json()
print( 'PARAMETERS:')
print( ' -- RECOMMENDED ACTIVITIES:')
df = pd.DataFrame(predicted_list[:5])
print(df)
