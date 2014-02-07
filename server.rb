require 'net/http'
require 'eventmachine'
require 'yaml'
require 'uri'

class ArtsyServer < EM::Connection

  def client_config
    @@client_config ||= client_config = YAML.load_file(Rails.root.join("/config.yml"))
  end

  def get_xapp_token
    url = URI.parse("https://artsyapi.com/api/v1/xapp_token?client_id=#{client_config['CLIENT_ID']}&client_secret=#{client_config['CLIENT_SECRET']}")
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    return res.body
  end

  def xapp_token
    @@xapp_token ||= get_xapp_token
  end

  def receive_data(data)
    if data.strip =~ /exit$/i
      EventMachine.stop
    else
      send_data(data)
    end
  end

  def post_init
    puts xapp_token
    send_artsy_logo
  end

  def send_artsy_logo
    file = File.open("artsylogo.txt")
    contents = ""
    file.each {|line|
      contents << line
    }
    puts contents
    send_data(contents)
  end

  EventMachine.run do
    # hit Control + C to stop
    Signal.trap("INT")  { EventMachine.stop }
    Signal.trap("TERM") { EventMachine.stop }

    EventMachine.start_server("0.0.0.0", 1234, ArtsyServer)
  end
end
