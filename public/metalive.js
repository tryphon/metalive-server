(function() {
  var __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  this.Metalive = (function() {
    function Metalive() {}

    Metalive.load = function(resource) {
      var tag;
      if (/\.js$/.test(resource)) {
        tag = document.createElement('script');
        tag.setAttribute("type", "text/javascript");
        tag.setAttribute("src", "http://" + (Metalive.domain()) + "/" + resource);
      }
      if (/\.css/.test(resource)) {
        tag = document.createElement('link');
        tag.setAttribute("rel", "stylesheet");
        tag.setAttribute("type", "text/css");
        tag.setAttribute("href", "http://" + (Metalive.domain()) + "/" + resource);
      }
      if (tag) {
        return document.getElementsByTagName("head")[0].appendChild(tag);
      }
    };

    Metalive.debug = function() {
      if (this.enable_debug != null) {
        return this.enable_debug;
      }
      return Metalive.dev();
    };

    Metalive.dev = function() {
      return /metalive.tryphon.dev/.test(location.href);
    };

    Metalive.domain = function() {
      if (Metalive.dev()) {
        return "metalive.tryphon.dev";
      } else {
        return "metalive.tryphon.eu";
      }
    };

    Metalive.log = function(message) {
      if (Metalive.debug()) {
        return console.log(message);
      }
    };

    Metalive.init = function() {
      if (this.already_init) {
        return;
      }
      this.already_init = true;
      this.load("mustache.js");
      this.load("juration.js");
      return this.load("base.css");
    };

    return Metalive;

  })();

  Metalive.init();

  this.Metalive.Stream = (function() {
    function Stream(id) {
      this.id = id;
      this.receivers = [];
    }

    Stream.prototype.api_url = function(path, schema) {
      var port;
      if (schema == null) {
        schema = "http";
      }
      port = schema === "ws" ? ":8080" : "";
      return "" + schema + "://" + (Metalive.domain()) + port + "/api/streams/" + this.id + "/" + path;
    };

    Stream.prototype.complete_event = function(event) {
      return event.occurred_at = new Date(event.occurred_at);
    };

    Stream.prototype.receive_event = function(json) {
      var event, receiver, _i, _len, _ref, _results;
      event = JSON.parse(json);
      this.complete_event(event);
      Metalive.log("dispatch " + (JSON.stringify(event)));
      _ref = this.receivers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        receiver = _ref[_i];
        _results.push(receiver.receive(event));
      }
      return _results;
    };

    Stream.prototype.retrieve_last_event = function() {
      var request;
      Metalive.log("retrieve last event of stream " + this.id);
      request = new XMLHttpRequest();
      request.open("GET", this.api_url("events/last.json"), true);
      request.onreadystatechange = (function(_this) {
        return function() {
          if (request.readyState === 4 && request.status === 200) {
            return _this.receive_event(request.responseText);
          }
        };
      })(this);
      return request.send(null);
    };

    Stream.prototype.init_web_socket = function() {
      var Socket, socket;
      Socket = __indexOf.call(window, "MozWebSocket") >= 0 ? MozWebSocket : WebSocket;
      Metalive.log("connet websocket to stream " + this.id);
      socket = new Socket(this.api_url("events.ws", "ws"));
      socket.onmessage = (function(_this) {
        return function(message) {
          return _this.receive_event(message.data);
        };
      })(this);
      return socket.onclose = (function(_this) {
        return function() {
          return Metalive.log("socket closed");
        };
      })(this);
    };

    Stream.prototype.display = function(target_id) {
      var target;
      if (target_id == null) {
        target_id = "metalive_current";
      }
      target = document.getElementById(target_id);
      this.receivers = [new Metalive.EventView(target)];
      this.retrieve_last_event();
      return this.init_web_socket();
    };

    Stream.prototype.search = function(form, target_id) {
      var request, target, term;
      if (target_id == null) {
        target_id = "metalive_search_result";
      }
      term = form.elements[0].value;
      Metalive.debug("search term: '" + term + "'");
      target = document.getElementById(target_id);
      request = new XMLHttpRequest();
      request.open("GET", this.api_url("events.json?term=" + term), true);
      request.onreadystatechange = (function(_this) {
        return function() {
          var event, events, _i, _len;
          if (request.readyState === 4 && request.status === 200) {
            events = JSON.parse(request.responseText);
            for (_i = 0, _len = events.length; _i < _len; _i++) {
              event = events[_i];
              _this.complete_event(event);
            }
            return new Metalive.EventsView(target).display(events);
          }
        };
      })(this);
      request.send(null);
      return false;
    };

    return Stream;

  })();

  this.Metalive.EventView = (function() {
    function EventView(target, current) {
      this.target = target;
      this.current = current != null ? current : true;
      this.template = "<p class='event'> <img class='cover' src='{{ description.cover }}'> <div class='description'> <span class='title'>{{ description.title }}</span> par&nbsp;<span class='artist'>{{ description.artist }}</span> sur&nbsp;l'album&nbsp;<span class='album'>{{ description.album }}</span> </div> <span class='since'>{{ description.distance_from_now }}</span> </p>";
    }

    EventView.prototype.complete = function(event) {
      var _base;
      event.description.distance_from_now = this.distance_from_now(event.occurred_at);
      return (_base = event.description).cover || (_base.cover = "http://" + (Metalive.domain()) + "/default-cover.png");
    };

    EventView.prototype.distance_from_now = function(time) {
      var distance_from_now, prefix;
      distance_from_now = (new Date() - time) / 1000;
      if (distance_from_now < 2) {
        return "à l'instant";
      } else {
        prefix = this.current ? "depuis" : "il y a";
        return prefix + " " + juration.stringify(distance_from_now, {
          format: 'short'
        });
      }
    };

    EventView.prototype.display = function(event) {
      this.complete(event);
      return this.target.innerHTML = this.render(event);
    };

    EventView.prototype.receive = function(event) {
      return this.display(event);
    };

    EventView.prototype.render = function(event) {
      Metalive.log("render " + (JSON.stringify(event)));
      return Mustache.render(this.template, event);
    };

    return EventView;

  })();

  this.Metalive.EventsView = (function() {
    function EventsView(target) {
      this.target = target;
      this.event_view = new Metalive.EventView(null, false);
    }

    EventsView.prototype.complete = function(events) {
      var event, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = events.length; _i < _len; _i++) {
        event = events[_i];
        _results.push(this.event_view.complete(event));
      }
      return _results;
    };

    EventsView.prototype.render = function(events) {
      var event, html, _i, _len;
      html = "<ol>";
      for (_i = 0, _len = events.length; _i < _len; _i++) {
        event = events[_i];
        html += "<li>" + (this.event_view.render(event)) + "</li>";
      }
      return html += "</ol>";
    };

    EventsView.prototype.display = function(events) {
      this.complete(events);
      return this.target.innerHTML = this.render(events);
    };

    return EventsView;

  })();

}).call(this);
