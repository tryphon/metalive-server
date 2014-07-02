function debug(string) {
    console.log(string);
}

function format_event(event, current) {
    description = event.description;

    distance_from_now = (new Date() - event.occurred_at) / 1000;

    if (distance_from_now < 2) {
        distance_from_now_text = "à l'instant";
    } else {
        prefix = current ? "depuis" : "il y a";
        distance_from_now_text = prefix + " " + juration.stringify(distance_from_now, { format: 'short' });
    }

    debug("distance: " + distance_from_now_text +  " title: " + description.title + " artist: " + description.artist + " album: " + description.album + " group: " + description.group);

    html = "<p class='event'>";

    var cover_url = "http://metalive.tryphon.eu/default-cover.png";
    if (description.cover != undefined) {
        cover_url = description.cover;
    }

    html += "<img class='cover' src='" + cover_url + "'/>";

    html += "<span class='title'>" + description.title + "</span> par <span class='artist'>" + description.artist + "</span><br/>";
    if (description.album != undefined) {
        html += "sur l\'album <span class='album'>" + description.album + "</span><br/>";
    }
    html += "<span class='since'>" + distance_from_now_text + "</span>";
    html += "</p>";

    return html;
}

function complete_event(event) {
    event.occurred_at = new Date(event.occurred_at);
}

function receive_event(json) {
    var event = eval('(' + json + ')');
    complete_event(event);

    debug("Event: " + event);

    var element = document.getElementById("current");
    element.innerHTML = format_event(event, true);
};

function init() {
    var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
    var ws = new Socket("ws:///metalive.tryphon.eu:8080/api/streams/test/events.ws");
    ws.onmessage = function(evt) {
        debug("Message: " + evt.data);
        receive_event(evt.data);
    };
    ws.onclose = function() { debug("socket closed"); };

    var request = new XMLHttpRequest();
    request.open("GET", "http://metalive.tryphon.eu/api/streams/test/events/last.json", true);
    request.onreadystatechange = function() {
        if (request.readyState == 4 && request.status == 200) {
            receive_event(request.responseText);
        }
    };
    request.send(null);
};

function receive_events(json) {
    var events = eval('(' + json + ')');

    var events_html = "<ul>";

    for (var i=0; i < events.length; i++) {
        var event = events[i];
        complete_event(event);
        events_html += "<ol>" + format_event(event, false) + "</ol>";
    }

    events_html += "</ul>";

    var element = document.getElementById("result");
    element.innerHTML = events_html;
};


function search(form) {
    term = form.elements[0].value;
    debug("Term: '" + term + "'");

    var request = new XMLHttpRequest();
    request.open("GET", "http://metalive.tryphon.eu/api/streams/test/events.json?term=" + term, true);
    request.onreadystatechange = function() {
        if (request.readyState == 4 && request.status == 200) {
            receive_events(request.responseText);
        }
    };
    request.send(null);
};
