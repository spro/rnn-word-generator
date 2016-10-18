somata = require 'somata'
require 'sample'

sample_service = somata.Service.create('sample', {
    sample=function(message, cb)
        if #message > 10 then
            cb("Input is too long")
        else
            local samples = sample_all(message)
            print('samples', samples)
            cb(nil, samples)
        end
    end
}, {heartbeat=2000})

sample_service:register()
