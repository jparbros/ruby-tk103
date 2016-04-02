require 'pry'
require 'socket'
require 'active_record'
require_relative 'models/position'
require_relative 'models/gps_update'

ActiveRecord::Base.logger = Logger.new("log/development.log")
ActiveRecord::Base.logger.level = 0

configuration = YAML::load(IO.read('db/config.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

HANDSHAKE = "BP00"
UPDATE    = "BR00"

def store_location(message)
  update = GPSUpdate.new(message)
  puts "You are at: #{update.position}"
  update.position.save!
end

def parse(message)
  begin
    head    = message[0]
    serial  = message[1..12]
    command = message[13..16]
    body    = message[17..-2]
    tail    = message[-1]

    # puts <<-eos
    #   head    #{head}
    #   serial  #{serial}
    #   command #{command}
    #   body    #{body}
    #   tail    #{tail}
    # eos

    case command
    when HANDSHAKE
      puts "Hello #{serial}"
    when UPDATE
      store_location(body)
    else
      puts "Sorry, I don't understand #{command}"
    end
  rescue Exception => e
    puts "Error: #{e}."
    puts e.backtrace
  end
end

puts "GPS server listening on port 12345"
server = TCPServer.open 80

loop do
  Thread.start(server.accept) do |client|
    puts "A client connected"

    loop do
      message = client.gets
      message = message.split(',')

      if message.first == '##'
        client.puts "LOAD"
      elsif message.first.to_i > 0 && message.first.size == 15
        client.puts "ON"
      end
    end

    client.close
  end
end
