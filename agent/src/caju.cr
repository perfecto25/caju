require "hardware"
require "msgpack"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "./status"


module Caju
  extend self

  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  # default cmdline vars
  cfgfile = "/etc/caju/caju.toml"
  daemon = false
  status = false

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
    
    parser.on("-d", "--daemon", "run as daemon") { daemon = true }
    parser.on("-s", "--status", "get monitor status") { status = true }

    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  abort "config file is missing", 1 if !File.file? cfgfile
  
  begin
    config = TOML.parse(File.read("/home/mreider/dev/crystal/caju/agent/config.toml"))
  rescue exception
    puts "unable to parse TOML: #{exception}"
    exit(1)
  end

  puts config
  puts daemon
  puts status

  # if daemon, start background proc
  if daemon == true
    puts "starting caju agent process"
    loop do
      sleep 5
  
      #payload = MessagePack.pack(Status.get_actual(config))
      actual = Status.get_actual(config)
      p actual
      payload = MessagePack.pack(actual.to_json)
      #payload = MessagePack.pack({"test" => "aaa"})

    #  payload = MessagePack.pack({
    #    "hostname" => actual["hostname"],
    #    "cpu" => actual["cpu"], 
    #     "cpu_pct" => PID_STAT.cpu_usage!,
    #     "mem" => Memory.sys_mem_info,
    #     "uptime" => Sys.get_uptime


      p payload
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
  end # daemon
  
  # if status return status
  if status == true
    puts "getting status"
    begin
      actual = Status.get_actual(config)
      puts actual
      puts "----"
      # iterate over config and check each limit vs actual
      Status.check_actual(config, actual)

    rescue error
      error.inspect_with_backtrace(STDOUT)
      exit 1
    end
  end


  
  #cpu = Hardware::CPU.new
  #PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
  #app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID

  



end # module
