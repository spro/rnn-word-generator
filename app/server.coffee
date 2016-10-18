polar = require 'somata-socketio'
somata = require 'somata'
config = require './config'
client = new somata.Client

app = polar config

app.get '/', (req, res) ->
    res.render 'index'

capitalize = (s) ->
    if s.length == 0
        return s
    s[0].toUpperCase() + s.slice(1)

app.get '/sample.json', (req, res) ->
    q = capitalize req.query.q?.trim() || ''
    client.remote 'sample', 'sample', q, (err, got) ->
        if err
            console.log "Error:", err
            res.send 500, err
        else
            res.json got

app.start()
