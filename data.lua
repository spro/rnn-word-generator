require 'helpers'

-- Reading 

function findFiles(dir, match)
    local files = {}
    local p = io.popen('find "' .. dir .. '" -type f')
    for file in p:lines() do
        if string.match(file, match) then
            table.insert(files, file)
        end
    end
    return files
end

function trimFilename(s)
    return s:split('/')[2]:split('%.')[1]
end

-- class_filenames = findFiles(opt.data_dir, '.txt')
class_filenames = {'data/Japanese.txt', 'data/Korean.txt', 'data/Italian.txt'}
class_filenames = {'data/Japanese.txt', 'data/Russian.txt', 'data/Irish.txt'}
class_counts = {}
class_weights = {}

classes = map(class_filenames, trimFilename)

all_words = {}
chars = {}
chars_inverse = {}
n_chars = 0
max_count = 1000

for oi = 1, #classes do 
    local class = classes[oi]
    local class_words = {}
    local li = 0

    for line in io.lines(opt.data_dir .. '/' .. class .. '.txt') do
        li = li + 1
        if li > 1 then
            local word = line
            local word_length = 0
            for char in unicodeChars(word) do
                if not chars[char] then
                    n_chars = n_chars + 1
                    chars[char] = n_chars
                    chars_inverse[n_chars] = char
                end
                word_length = word_length + 1
            end
            if word_length > 1 then
                table.insert(class_words, {oi, word})
            end
        end
    end

    class_counts[oi] = li

    if class_counts[oi] >= max_count then
        for ni = 1, max_count do
            table.insert(all_words, randomChoice(class_words))
        end
    else
        for ni = 1, class_counts[oi] do
            table.insert(all_words, class_words[ni])
        end
        if max_count > class_counts[oi] then
            for ni = 1, (max_count - class_counts[oi]) do
                table.insert(all_words, randomChoice(class_words))
            end
        end
    end
end

data = {
    n_classes = #classes,
    n_chars = n_chars,
    classes = classes,
    chars = chars,
    chars_inverse = chars_inverse,
}
torch.save('data.t7', data)

