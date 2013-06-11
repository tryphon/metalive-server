require 'em-websocket'
require 'json'
require 'evma_httpserver'
require 'mysql2/em'
require 'uuid'
require 'cgi'
require 'xmlsimple'
require 'em-http'

class ApiServer < EM::Connection
  include EM::HttpServer

  def initialize(channel, mysql_client)
    @channel = channel
    @mysql_client = mysql_client
  end

  def post_init
    super
    no_environment_strings
  end

  def uuid_generator
    @uuid ||= UUID.new
  end

  def process_http_request
    # the http request details are available via the following instance variables:
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_headers
    case @http_request_method
    when 'POST'
      create_event
    when 'GET'
      if @http_path_info == '/last'
        last_event
      else
        search_events
      end
    end
  end

  def create_event
    event = JSON.parse(@http_post_content)
    event["occurred_at"] ||= Time.now
    event["uuid"] = uuid = uuid_generator.generate

    puts "Transmit #{event.inspect}"
    @channel.push event

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'application/json'
    response.content = "{uuid: #{uuid}}"
    response.send_response
  end

  def last_event
    query = "select * from events order by occurred_at desc limit 1;"
    puts query

    deferred_query = @mysql_client.query query
    deferred_query.callback do |result|
      event = result.first

      event.delete("id")
      event["description"] = JSON.parse(event["description"])

      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.content_type 'application/json'
      response.content = event.to_json
      response.send_response
    end
  end

  def search_events
    search = @http_query_string

    sql_where = "where description REGEXP '#{search}'" if search
    query = "select * from events #{sql_where} order by occurred_at desc limit 10;"
    puts query

    deferred_query = @mysql_client.query query
    deferred_query.callback do |result|
      events = result.map do |event|
        event.delete("id")
        event["description"] = JSON.parse(event["description"])

        event
      end

      response = EM::DelegatedHttpResponse.new(self)
      response.status = 200
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.content_type 'application/json'
      response.content = events.to_json
      response.send_response
    end
  end

end

EventMachine.run {
  @channel = EM::Channel.new

  @completed_channel = EM::Channel.new

  @mysql_client = Mysql2::EM::Client.new(:username => "metalive", :password => "Edau2Olein", :database => "metalive")

  EM.start_server '0.0.0.0', 8080, ApiServer, @channel, @mysql_client

  def complete_with_cover(event, &callback)
    description = event["description"]
    unless description and description["group"] == "MUSIC" and description["artist"] and description["album"]
      callback.call
      return
    end

    artist = CGI.escape(description["artist"])
    album = CGI.escape(description["album"])

    url = "http://ws.audioscrobbler.com/2.0/?method=album.search&album=#{album}&api_key=a3eeee82336a4d3cc8b947bc8b5e11d1&format=json"

    http = EM::HttpRequest.new(url).get
    http.callback do
      begin
        if http.response_header.status == 200
          json = JSON.parse(http.response)
          first_album = json["results"]["albummatches"]["album"].first if json["results"]["albummatches"]

          if first_album
            image = first_album["image"].find { |image| image["size"] == "medium" }
            event["description"]["cover"] = image["#text"] if image
          end
        end
      rescue => e
        puts "Failed to find cover: #{e}"
      end

      callback.call
    end
  end

  def save_event(event)
    sql_occurred_at = event["occurred_at"].strftime("%Y-%m-%d %H:%M:%S")
    sql_description = @mysql_client.escape event["description"].to_json

    query = "INSERT into events (occurred_at,description,uuid) values ('#{sql_occurred_at}', '#{sql_description}', '#{event["uuid"]}')"
    puts query

    @mysql_client.query query
  end

  @channel.subscribe { |event|
    complete_with_cover(event) do
      save_event event
      @completed_channel.push event
    end
  }

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8081, :debug => true) do |ws|
    ws.onopen {
      sid = @completed_channel.subscribe { |msg| ws.send msg.to_json }
      # @channel.push "#{sid} connected!"

      # ws.onmessage { |msg|
      #   @channel.push "<#{sid}>: #{msg}"
      # }

      ws.onclose {
        @completed_channel.unsubscribe(sid)
      }
    }
  end

}
