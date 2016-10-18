require 'nn'
require 'rnn'
require 'dpnn'
require 'helpers'

-- Parse command line arguments

cmd = torch.CmdLine()
cmd:text()

cmd:option('-class', 1, 'Class to sample')
cmd:option('-prime_text', '', 'Text to start sample from')
cmd:option('-max_length', 20, 'Maximum output length')

opt = cmd:parse(arg)

function makeCharacterInput(target_class, char)
    return {torch.LongTensor({target_class}), torch.LongTensor({char})}
end

model = torch.load('model.t7')
data = torch.load('data.t7')

SOW = data.n_chars + 1
EOW = data.n_chars + 2

-- dropout = model:get(4)
-- dropout.p = 0.0

model:remember()

function sample(target_class, start_chars)
    model:forget()
    local sampled = ''

    -- Start with SOW
    local inputs = makeCharacterInput(target_class, SOW)

    -- Input the starting characters
    for start_char in unicodeChars(start_chars) do
        sampled = sampled .. start_char
        -- Only if the character is known
        if data.chars[start_char] ~= nil then
            model:forward(inputs)
            inputs = makeCharacterInput(target_class, data.chars[start_char])
        end
    end

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

function sample_all(prime_text)
    local all_sampled = {}
    for ci = 1, data.n_classes do
        local sampled = sample(ci, prime_text)
        print(data.classes[ci], sampled)
        table.insert(all_sampled, {data.classes[ci], sampled})
    end
    return all_sampled
end

print(sample_all(opt.prime_text))
