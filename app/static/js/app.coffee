React = require 'react'
ReactDOM = require 'react-dom'
somata = require './somata-stream'
ContentEditable = require 'react-contenteditable'
KefirBus = require 'kefir-bus'
d3 = require 'd3'

color = d3.scaleOrdinal(d3.schemeCategory10)

capitalize = (s) ->
    if s.length == 0
        return s
    s.split(' ').map (w) ->
        w[0].toUpperCase() + w.slice(1)
    .join(' ')

Spinner = ({children}) ->
    <div className='spinner-container'>
        <div className='spinner'>
            <i className='fa fa-spin fa-circle-o-notch' />
            {if children?
                <span>{children}</span>
            }
        </div>
    </div>

Error = ({children}) ->
    <div className='error-container'>
        <div className='error'>
            <i className='fa fa-warning' />
            {if children?
                <span>{children}</span>
            }
        </div>
    </div>

App = React.createClass
    getInitialState: ->
        loading: false

    componentDidMount: ->
        @q$ = KefirBus()
        @q$.filter((q) -> q.length > 0).onValue(@search)
        # @refs.input.focus()

    changeQ: (q) ->
        q = capitalize q
        @setState {q}
        if q.length == 0
            @setState {samples: []}
        @q$.emit q

    search: (q) ->
        @setState {loading: true}
        somata.remote('sample', 'sample', q)
            .onValue (samples) =>
                console.log '[search] samples =', samples
                samples.forEach (sample) =>
                    sample.sample = sample.sample.replace(new RegExp('^' + @state.q), '')
                @setState {samples, error: null, loading: false}
            .onError (error) =>
                @setState {error, loading: false}

    render: ->
        <div className='container'>
            <div className='fields'>
                <span>{@state.q}</span>
                <Editable value=@state.q onChange=@changeQ />
                <span>{@state.q}</span>
            </div>

            <div className='samples'>
                {@state.samples?.map (sample) =>
                    # console.log '[sample]', sample
                    <div className={'sample'} key=sample.class_name>
                        <span style={color: color(sample.class_name)}>{sample.sample}</span>
                    </div>
                }
            </div>

            {if @state.samples?
                <Key class_names={@state.samples.map (sample) -> sample.class_name} />
            }

            {if @state.loading
                <Spinner />
            }
            {if @state.error
                <Error>{@state.error}</Error>
            }
        </div>

Key = ({class_names}) ->
    <div className='key'>
        {class_names.map (class_name) ->
            <div key=class_name>
                <span style={backgroundColor: color(class_name)}>{class_name}</span>
            </div>
        }
    </div>

Editable = React.createClass
    getInitialState: ->
        value: ''

    componentDidMount: ->
        @focus()

    componentWillReceiveProps: (new_props) ->
        if value = new_props.value
            @setState {value}, @selectEnd

    onChange: (e) ->
        value = e.target.value
        @setState {value}
        @props.onChange?(value)

    onFocus: ->
        @selectEnd()

    onKeyDown: (e) ->
        important_keys = ['Delete', 'Backspace']
        if e.key == 'Enter'
            e.preventDefault()
            @props.onChange?(@state.value)
        else if !e.key.match(/^[a-zA-Z ']/) and e.key not in important_keys
            console.log "Avoiding", e.key
            e.preventDefault()

    selectEnd: ->
        el = @refs.input.htmlEl
        if el.innerHTML.length
            range = document.createRange()
            sel = window.getSelection()
            range.setStart(el, 1)
            range.collapse(true)
            sel.removeAllRanges()
            sel.addRange(range)

    focus: ->
        el = @refs.input.htmlEl
        el.focus()

    render: ->
        <ContentEditable ref='input' html={@state.value} onChange=@onChange disabled=@props.disabled onKeyDown=@onKeyDown onBlur=@save onFocus=@onFocus />

ReactDOM.render <App />, document.getElementById 'app'

