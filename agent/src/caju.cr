require "hardware"
require "msgpack"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "yaml"
require "./status"
require "./log"


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
    config = TOML.parse(File.read(cfgfile)).as(Hash)
  rescue exception
    abort "unable to parse TOML: #{exception}", 1
  end

  # begin
  #   config = YAML.parse(File.read(cfgfile))
  # rescue exception
  #   abort "unable to read config file", 1
  # end
  log = init_log(config)

  # if daemon, start background proc
  if daemon == true
    puts "starting caju agent process"
    loop do
      sleep 5
      payload = Status.get_actual(config, log).to_msgpack
      #payload = MessagePack.pack({"test" => "aaa"})
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
  if status == true && daemon == false
    puts "getting status"
    begin
      actual = Status.get_actual(config, log)
      # iterate over config and check each limit vs actual
      Status.check_status(config, actual, log)

    rescue error
      p error
      error.inspect_with_backtrace(STDOUT)
      exit 1
    end
  end


  
  #cpu = Hardware::CPU.new
  #PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
  #app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID

  



end # module
