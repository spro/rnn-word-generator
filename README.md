# torch-rnn-word-generator

Generates words character-by-character with an RNN given a target class (the inverse of [torch-rnn-word-classifier](https://github.com/spro/torch-rnn-word-classifier))

![](https://i.imgur.com/49ySbHs.png)

## Training

```
th train.lua

-data_dir            Data directory, containing a text file per class [data]
-hidden_size         Hidden size of LSTM layer [200]
-dropout             Dropout at last layer [0.5]
-learning_rate       Learning rate [0.001]
-learning_rate_decay Learning rate decay [1e-07]
-max_length          Maximum output length [20]
-n_epochs            Number of epochs to train [100000]
```

## Generating

```
$ th generate.lua -n_names 3

(French)
Armelle
Daneau
Tartan

(Japanese)
Ashi
Dano
Tokioki

(Italian)
Arlaninio
Dani
Tartani

(Chinese)
Ain
Dei
Ten
```
