require "hardware"
require "msgpack"
require "http/client"


module Caju
  extend self
  io = IO::Memory.new 
  
  cpu = Hardware::CPU.new
  #PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
  #app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID

  


  loop do
    sleep 1

    mem = Hardware::Memory.new
    
    # 
    payload = MessagePack.pack({
      "hostname" => "abc123",
      "cpu" => cpu.usage!.to_i, 
      #"cpu_pct" => PID_STAT.cpu_usage!,
      "mem" => mem.used.to_i,
      "mem_pct" => mem.percent.to_i
    })

    response = HTTP::Client.post("http://localhost:8080", 
      headers: HTTP::Headers {
        "Content-Type" => "application/msgpack",
        "Accept" => "application/msgpack"

      },
      body: payload
    )
    
    if response.success?
      result = MessagePack.unpack(response.body)
      puts result
    else 
      puts "Error #{response.status_code}"
    end
  end # loop
end # module
