require "option_parser"
require "toml"
require "msgpack"
require "./log"
require "./sysinfo"
require "./table"


module Caju
  extend self

  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  # default cmdline vars
  cfgfile = "/etc/caju/caju.toml"
  daemon = false
  status = false
  info = false

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
    parser.on("-i", "--info", "show system information") { info = true }
    parser.on("-s", "--status", "get monitor status") { status = true }

    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

  if info == false
    abort "config file is missing", 1 if !File.file? cfgfile
    begin
      config = TOML.parse(File.read(cfgfile)).as(Hash)
    rescue exception
      abort "unable to parse TOML: #{exception}", 1
    end
    log = init_log(config)  
    log.info { config }

  end

  


  # if daemon, start background proc
  
  if daemon == true
    puts "starting caju agent process"
    loop do
      sleep 5.seconds
      puts "running demon"
      #payload = Status.get_payload(config, log).to_msgpack
      #payload = MessagePack.pack({"test" => "aaa"})
      #response = HTTP::Client.post("http://localhost:8090", 
      #  headers: HTTP::Headers {
      #    "Content-Type" => "application/msgpack",
      #    "Accept" => "application/msgpack"
      #  },
      #  body: payload
      #)
      
      #if response.success?
      #  result = MessagePack.unpack(response.body)
      #  puts result
      #else 
      #  puts "Error #{response.status_code}"
      #end
    end # loop
  end # daemon

  if info == true
    # show system info
    begin
      sysinfo = Caju::SysInfo::Sysinfo.new
      Caju::Table.print_table(sysinfo.to_json)
      
    end
  end

  # if status return status
  if status == true && daemon == false
    puts "getting status"
    begin
      sysinfo = Caju::SysInfo::Sysinfo.new
      puts sysinfo
#      puts sys_info.to_json
    end
  end
  

end # Module
