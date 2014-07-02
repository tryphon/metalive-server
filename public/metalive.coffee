class @Metalive
  @load: (resource) ->
    if /\.js$/.test(resource)
      tag = document.createElement 'script'
      tag.setAttribute "type", "text/javascript"
      tag.setAttribute "src", "http://#{Metalive.domain()}/#{resource}"

    if /\.css/.test(resource)
      tag = document.createElement 'link'
      tag.setAttribute "rel", "stylesheet"
      tag.setAttribute "type", "text/css"
      tag.setAttribute "href", "http://#{Metalive.domain()}/#{resource}"

    if tag
      document.getElementsByTagName("head")[0].appendChild tag

  @debug: () ->
    return @enable_debug if @enable_debug?
    Metalive.dev()

  @dev: () ->
    /metalive.tryphon.dev/.test(location.href)

  @domain: () ->
    if Metalive.dev()
      "metalive.tryphon.dev"
    else
      "metalive.tryphon.eu"

  @log: (message) ->
    console.log message if Metalive.debug()

  @init: () ->
    return if @already_init
    @already_init = true
    @load "mustache.js"
    @load "juration.js"
    @load "base.css"

Metalive.init()

class @Metalive.Stream
  constructor: (@id) ->
    @receivers = []

  api_url: (path, schema = "http") ->
    port = if schema == "ws" then ":8080" else ""
    "#{schema}://#{Metalive.domain()}#{port}/api/streams/#{@id}/#{path}"

  complete_event: (event) ->
    event.occurred_at = new Date event.occurred_at

  receive_event: (json) ->
    event = JSON.parse json
    @complete_event event
    Metalive.log "dispatch #{JSON.stringify(event)}"

    receiver.receive(event) for receiver in @receivers

  retrieve_last_event: ->
    Metalive.log "retrieve last event of stream #{@id}"

    request = new XMLHttpRequest()
    request.open "GET", @api_url("events/last.json"), true
    request.onreadystatechange = () =>
      if request.readyState == 4 && request.status == 200
        @receive_event request.responseText

    request.send null

  init_web_socket: ->
    Socket = if "MozWebSocket" in window then MozWebSocket else WebSocket

    Metalive.log "connet websocket to stream #{@id}"

    socket = new Socket(@api_url("events.ws", "ws"))
    socket.onmessage = (message) =>
      @receive_event message.data

    socket.onclose = () =>
      Metalive.log "socket closed"

  display: (target_id = "metalive_current") ->
    target = document.getElementById(target_id);
    @receivers = [ new Metalive.EventView(target) ]

    @retrieve_last_event()
    @init_web_socket()

  search: (form, target_id = "metalive_search_result") ->
    term = form.elements[0].value
    Metalive.debug("search term: '" + term + "'")

    target = document.getElementById(target_id);

    request = new XMLHttpRequest()
    request.open "GET",  @api_url("events.json?term=#{term}"), true
    request.onreadystatechange = () =>
      if request.readyState == 4 && request.status == 200
        events = JSON.parse request.responseText
        @complete_event event for event in events
        new Metalive.EventsView(target).display(events)

    request.send null

    false

class @Metalive.EventView
  constructor: (@target, @current = true) ->
    @template = "<p class='event'>
      <img class='cover' src='{{ description.cover }}'>
      <span class='title'>{{ description.title }}</span>
      par&nbsp;<span class='artist'>{{ description.artist }}</span>
      sur&nbsp;l'album&nbsp;<span class='album'>{{ description.album }}</span>
      <span class='since'>{{ description.distance_from_now }}</span>
      </p>
      "

  complete: (event) ->
    event.description.distance_from_now = @distance_from_now(event.occurred_at)
    event.description.cover ||= "http://#{Metalive.domain()}/default-cover.png"

  distance_from_now: (time) ->
    distance_from_now = (new Date() - time) / 1000;

    if distance_from_now < 2
      "à l'instant";
    else
      prefix = if @current then "depuis" else "il y a"
      prefix + " " + juration.stringify(distance_from_now, { format: 'short' })

  display: (event) ->
    @complete event
    @target.innerHTML = @render(event)

  receive: (event) -> @display(event)

  render: (event) ->
    Metalive.log "render #{JSON.stringify(event)}"
    Mustache.render @template, event

class @Metalive.EventsView
  constructor: (@target) ->
    @event_view = new Metalive.EventView(null, false)

  complete: (events) ->
    @event_view.complete event for event in events

  render: (events) ->
    html = "<ol>"
    html += "<li>#{@event_view.render(event)}</li>" for event in events
    html += "</ol>"

  display: (events) ->
    @complete events
    @target.innerHTML = @render events
