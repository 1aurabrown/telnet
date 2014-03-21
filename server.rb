require 'net/http'
require 'eventmachine'
require 'yaml'
require 'uri'
require 'json'

module ArtsyServer
  def client_config
    client_config ||= client_config = YAML.load_file("config.yml")
  end

  def get_xapp_token
    uri = URI("https://artsyapi.com/api/v1/xapp_token?client_id=#{client_config['CLIENT_ID']}&client_secret=#{client_config['CLIENT_SECRET']}")

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) {|http|
      req = Net::HTTP::Get.new uri
      response = http.request req
      return JSON.parse(response.body)["xapp_token"]
    }
  end

  def xapp_token
    xapp_token ||= get_xapp_token
  end

  def receive_data(data)
    if data.strip =~ /exit$/i
      EventMachine.stop
    else
      send_data(data)
    end
  end

  def post_init
    send_artsy_logo
    puts xapp_token
  end

  def send_artsy_logo
    file = File.open("artsylogo.txt")
    contents = ""
    file.each {|line|
      contents << line
    }
    send_data(contents)
  end
end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("0.0.0.0", 23, ArtsyServer)
end
