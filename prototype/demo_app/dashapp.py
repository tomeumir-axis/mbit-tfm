from datetime import datetime  
from datetime import timedelta  
import dash
from dash import html
from dash import dcc
from dash import dash_table
import requests
import pandas as pd


api_url = 'http://localhost:5000/predict'

app = dash.Dash(__name__)


app.layout = html.Div(
    id='div_main',
    #className='tweelve columns',
    children=[
        ## Header
        html.Div(
            id='div_header',
            children=[
                html.H1('MBIT School'),
                html.H2('Executive master in Data Science (2020-2021)'),
                html.H3('by Cyberguerrilla Mbit Group'),
                html.Br(),
            ]
        ),
        ## Form
        html.Div(
            id='div_form',
            children=[
                # Date
                html.Tr([
                    html.Th(html.H4('Excursion date: ')), 
                    html.Th(dcc.DatePickerSingle(
                                id='excursion_date',
                                min_date_allowed=datetime.now(), 
                                max_date_allowed=datetime.now() + timedelta(days=5,minutes=0), 
                                initial_visible_month=datetime.now(), 
                                date=datetime.now() 
                                )
                            )
                ]),
                # Age, ADT, CHD and INF
                html.Table(
                    className='table',
                    children = 
                    [
                        html.Tr([
                            html.Th(html.H4('Age:')),
                            html.Th(html.H4('ADT:')),
                            html.Th(html.H4('CHD:')),
                            html.Th(html.H4('INF:')),
                        ]),
                        html.Tr([
                            html.Th(dcc.Input(id='age', type='number', min=18, max=90, step=1, value=49)),
                            html.Th(dcc.Input(id='adt', type='number', min=1, max=5, step=1, value=2)),
                            html.Th(dcc.Input(id='chd', type='number', min=0, max=5, step=1, value=0)),
                            html.Th(dcc.Input(id='inf', type='number', min=0, max=5, step=1, value=0))
                        ]),
                    ]
                ),
                # Date
                html.H4('Price per pax: '), 
                dcc.Slider(
                            id="price",
                            min = 0,
                            max = 300,
                            step=10,
                            value=150,
                            marks={
                                0: {'label': '0'},
                                50: {'label': '50'},
                                100: {'label': '100'},
                                150: {'label': '150'},
                                200: {'label': '200'},
                                250: {'label': '250'},
                                300: {'label': '300'}
                            }
                ),
             
                html.Br(),
                html.Button('Submit', id='submit', n_clicks=0)   
            ]
        ), # end of div_form
        html.Br(),
        html.Div(id = 'div_predict')
    ]
)

@app.callback(
    [dash.dependencies.Output('div_predict', 'children')],
    [dash.dependencies.Input('submit', 'n_clicks')],
    [dash.dependencies.State('excursion_date', 'date'),
     dash.dependencies.State('age', 'value'),
     dash.dependencies.State('adt', 'value'),
     dash.dependencies.State('chd', 'value'),
     dash.dependencies.State('inf', 'value'),
     dash.dependencies.State('price', 'value')]
)
def predict(n_click, excursion_date, age, adt, chd, inf, price):
    if n_click == 0:
        return [""]
    data_form = {
    'excursion_date':excursion_date[:10],
    'lead_pax_age':age,
    'adt':adt,
    'chd':chd,
    'inf':inf,
    'price_per_pax':price
    }
    
    print('')
    print( ' -- RECOMMENDED ACTIVITIES for:')
    print( data_form)
    print('')
    r = requests.post(api_url, json=data_form)
    predicted_list = r.json()
    df = pd.DataFrame(predicted_list[:5])
    print( df)
    
    data = df.to_dict("records")
    cols = [{"name": i, "id": i} for i in df.columns]
    child = dash_table.DataTable(
                id='table',
                data=data, 
                columns=cols,
                style_cell={'width': '50px',
                            'height': '30px',
                            'textAlign': 'left'}
            )
    return [child]


if __name__ == '__main__':
    app.run_server(host='localhost', port=6969, debug=True)

print( 'bye bye!')
