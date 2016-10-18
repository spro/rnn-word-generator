require 'nn'
require 'rnn'
require 'dpnn'
require 'optim'
display = require 'display'

-- Parse command line arguments

cmd = torch.CmdLine()
cmd:text()

cmd:option('-data_dir', 'data', 'Data directory, containing a text file per class')
cmd:option('-hidden_size', 200, 'Hidden size of LSTM layer')
cmd:option('-dropout', 0.5, 'Dropout at last layer')
cmd:option('-learning_rate', 0.001, 'Learning rate')
cmd:option('-learning_rate_decay', 1e-7, 'Learning rate decay')
cmd:option('-max_length', 20, 'Maximum output length')
cmd:option('-n_epochs', 100000, 'Number of epochs to train')

opt = cmd:parse(arg)

require 'data' -- Require once options are set

-- Building the model
--------------------------------------------------------------------------------

n_chars_plus = data.n_chars + 2 -- plus start and end markers

rnn = nn.Sequential()
    :add(nn.FastLSTM(opt.hidden_size, opt.hidden_size))
    :add(nn.FastLSTM(opt.hidden_size, n_chars_plus))

parallel_input = nn.Sequential()
    :add(
        nn.ParallelTable(1, 1)
            :add(nn.OneHot(data.n_classes))
            :add(nn.OneHot(n_chars_plus))
    )
    :add(nn.JoinTable(2))

model = nn.Sequential()
    :add(parallel_input)
    :add(nn.Linear(data.n_classes + n_chars_plus, opt.hidden_size))
    :add(nn.Sequencer(rnn))
    :add(nn.Dropout(opt.dropout))
    :add(nn.LogSoftMax())

SOW = data.n_chars + 1
EOW = data.n_chars + 2

-- Set up optimization

local criterion = nn.SequencerCriterion(nn.ClassNLLCriterion())

local iter = 0
local errs = {}

local optim_config = {
	learningRate = opt.learning_rate,
	learningRateDecay = opt.learning_rate_decay,
}

local optim_state = {}

parameters, gradients = model:getParameters()

model:remember()

-- Training and sampling
--------------------------------------------------------------------------------

-- Run a loop of optimization

feval = function(parameters_new)
    if parameters ~= parameters_new then
        parameters:copy(parameters_new)
    end

    model:forget()
    model:zeroGradParameters()

    -- Choose a training smaple
    local target = randomChoice(all_words)
    local target_class = target[1]
    local target_word = target[2]

    -- Build table of character indexes starting with SOW and ending with EOW
    local char_seq = {SOW}
    for char in unicodeChars(target_word) do
        table.insert(char_seq, data.chars[char])
    end
    table.insert(char_seq, EOW)
    local word_length = #char_seq

    -- Build decoder input (target class, SOW to second-to-last character) and target (first character to EOW)
    local seq = torch.LongTensor(char_seq)
    local class_inputs = torch.LongTensor(word_length - 1):fill(target_class)
    local char_inputs = seq:sub(1, -2)
    local char_targets = seq:sub(2, -1)
    local inputs = {class_inputs, char_inputs}

    -- Get outputs and error
    local outputs = model:forward(inputs)
    local err = criterion:forward(outputs, char_targets) / word_length

    -- Gradients
    local gradOutputs = criterion:backward(outputs, char_targets)
    local gradInputs = model:backward(inputs, gradOutputs)

    iter = iter + 1

    return err, gradients
end

function makeCharacterInput(target_class, char)
    return {torch.LongTensor({target_class}), torch.LongTensor({char})}
end

-- Sample given a class and starting character

function sample(target_class, start_char)
    model:forget()
    local sampled = ''

    -- Start with SOW
    local inputs = makeCharacterInput(target_class, SOW)
    model:forward(inputs)

    -- Input the starting character
    sampled = sampled .. start_char
    inputs = makeCharacterInput(target_class, data.chars[start_char])

    for i = 1, opt.max_length do
        local output = model:forward(inputs):view(-1)
        local max_score, max_index = output:max(1)

        -- Stop at EOW
        if max_index[1] == EOW then
            break

        -- Or add to sampled string
        else
            local char = data.chars_inverse[max_index[1]]
            sampled = sampled .. char
        end

        -- Use the chosen character for the next input
        inputs = makeCharacterInput(target_class, max_index[1])
    end
    return sampled
end

-- Run optimization for n_epochs

err = 0
for i = 1, opt.n_epochs do
    local _, fs = optim.adam(feval, parameters, optim_config, optim_state)
    err = err + fs[1]

    -- Plot every 10
    if i % 10 == 0 then
        err = err / 10
        table.insert(errs, {iter, err})
        display.plot(errs, {win='errs'})
        err = 0
    end

    -- Sample every 100
    if i % 100 == 0 then
        print('epoch', i, '-----------------\n')
        for ci = 1, data.n_classes do
            print('(' .. data.classes[ci] .. ')')
            print(sample(ci, 'A'))
            print(sample(ci, 'B'))
            print(sample(ci, 'C'))
            print('')
        end
    end

    -- Save every 1000
    if i % 1000 == 0 then
        torch.save('model.t7', model)
        print("Saved model.")
    end
end

