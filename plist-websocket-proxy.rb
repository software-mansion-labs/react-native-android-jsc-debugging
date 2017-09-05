#!/usr/bin/env ruby

require 'cfpropertylist'
require 'socket'
require 'sinatra/base'
require "sinatra/json"
require 'sinatra-websocket'
require 'json'
require 'pry'

# config
ANDROID_HOST = '127.0.0.1'
ANDROID_PORT = 9123
WEBSOCKET_SERVER_PORT = 9003

# const
GETLISTING = CFPropertyList::List.new
GETLISTING.value = CFPropertyList.guess({messageName: 'WIRApplicationGetListingMessage'})
EXECUTION_CONTEXT = { method:'Runtime.executionContextCreated', params: { context: { id: 1, origin: 'reactNative', name: 'reactNative' } } }

module PListUtils
  def self.size(str)
    [str.size].pack('L>')
  end

  def self.msg(cfplist)
    bin = cfplist.to_str
    [size(bin), bin].join
  end

  def self.socket_msg(target_identifier, json)
    socket = CFPropertyList::List.new
    socket.value = CFPropertyList.guess(
      messageName: 'WIRSocketDataMessage',
      msgData: {
        WIRTargetIdentifierKey: target_identifier.to_i,
        WIRSocketDataKey: json
      }
    )
    socket
  end

  def self.setup_msg(target_identifier)
    msg = CFPropertyList::List.new
    msg.value = CFPropertyList.guess(
      messageName: 'WIRSocketSetupMessage',
      msgData: {
        WIRTargetIdentifierKey: target_identifier.to_i,
        WIRConnectionIdentifierKey: "RN-debug-#{target_identifier}",
        WIRSenderKey: 'RNDebugBridge'
      }
    )
    msg
  end
end

class AndroidSocket
  attr_reader :socket, :connected
  def initialize(host, port, sinatra_app)
    @host = host
    @port = port.to_i
    @sinatra_app = sinatra_app
    @connected = false
  end

  def connect!
    @socket = TCPSocket.new @host, @port
    @connected = true
  end

  def connect
    connect!
  rescue
    false
  end

  def main_loop
    loop do
      connect!
      @socket.write(PListUtils.msg(GETLISTING))
      interal_loop
    end
  end

  def interal_loop
    loop { loop_body }
  end

  def loop_body
    begin
      newdata = @socket.recv(200000)
      buf = [buf, newdata].join
      raise "Connection broken" if newdata.length == 0
      while true
        break if buf.size < 4
        leng = buf[0..3].unpack('L>').first
        break if buf.size < (4 + leng)
        data = buf[4..(4+leng-1)]
        msg = CFPropertyList::List.new(data: data)
        parsed = CFPropertyList.native_types(msg.value)
        if parsed['messageName'] == 'WIRRawDataMessage'
          @sinatra_app.websocket.send(parsed['msgData']['WIRRawDataKey']) if @sinatra_app.websocket
        elsif parsed['messageName'] == 'WIRListingMessage'
          @sinatra_app.debugging_targets = parsed['msgData']['WIRListingKey']
        else
        end

        buf = buf[(4+leng)..-1] || ""
      end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end
end

class Proxy < Sinatra::Base
  set :server, 'thin'
  set :debugging_targets, {}
  set :websocket, nil
  set :target_identifier, nil
  set :port, WEBSOCKET_SERVER_PORT
  set :bind, '0.0.0.0'
  set :json_encoder, :to_json
  set :android_socket, AndroidSocket.new(ANDROID_HOST, ANDROID_PORT, self)

  Thread.new { settings.android_socket.main_loop }

  get '/json' do
    json(settings.debugging_targets.map do |i, target|
      {
        id: "reactNative-#{i}",
        title: "ReactNative Application (#{target['WIRTitleKey']} #{i})",
        devtoolsFrontendUrl: "https://chrome-devtools-frontend.appspot.com/serve_file/@7d149ef5473e980f0b3babd4d0f2839cb9338e73/inspector.html?&ws=localhost:9003/ws/#{i}",
        webSocketDebuggerUrl: "ws://localhost:9003/ws/#{i}",
        faviconUrl: "https://facebook.github.io/react-native/img/favicon.png?2",
        type: 'device'
      }
    end)
  end

  get '/json/version' do
    json(
      Browser: 'Android/ReactNative debug bridge',
      :'Protocol-Version' => '1.2'
    )
  end

  get '/ws/:number' do
    if !request.websocket?
      "go to /"
    else
      request.websocket do |ws|
        ws.onopen do
          if settings.android_socket.connected && !settings.websocket
            settings.websocket = ws
            settings.target_identifier = params['number'].to_i
            settings.android_socket.socket.write(PListUtils.msg(PListUtils.setup_msg(settings.target_identifier)))
          end
        end
        ws.onmessage do |msg|
          EM.next_tick do
            parsed_message = JSON(msg)
            if parsed_message['method'] == 'Runtime.enable'
              settings.websocket.send(JSON(EXECUTION_CONTEXT))
            end
            settings.android_socket.socket.write(PListUtils.msg(PListUtils.socket_msg(settings.target_identifier, msg))) if settings.android_socket.connected
          end
        end
        ws.onclose do
          settings.websocket = nil
        end
      end
    end
  end
end

# pry_thread = Thread.new { binding.pry }
Proxy.run!
