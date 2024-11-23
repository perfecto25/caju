require "hardware"
require "msgpack"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "./memory"
require "./cpu"
require "./sys"


module Caju
  extend self
  VERSION = "0.1.0"

  OptionParser.parse do |parser|
    parser.banner = "Caju - system monitoring tool"
    parser.on("-c CONFIG", "--config=CONFIG", "path to config file") { |config| cfgfile = config }
    parser.on "-h", "--help", "Show help" do
      STDOUT.puts parser
      exit(0)
    end
    parser.on "-v", "--version", "Show version" do
      STDOUT.puts VERSION
      exit(0)
    end
    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  config = TOML.parse(File.read("/home/mreider/dev/crystal/caju/agent/config.toml"))
  puts config


  
  #cpu = Hardware::CPU.new
  #PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
  #app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID

  


  loop do
    sleep 5

    
  
    

    payload = MessagePack.pack({
      "hostname" => System.hostname,
      "cpu" => Cpu.get_cpu_info, 
      #"cpu_pct" => PID_STAT.cpu_usage!,
      "mem" => Memory.sys_mem_info,
      "uptime" => Sys.get_uptime
     # "mem_pct" => mem[1]  
    })

    response = HTTP::Client.post("http://localhost:8090", 
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
