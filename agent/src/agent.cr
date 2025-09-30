require "hardware"
require "msgpack"
require "http/client"
require "option_parser"
require "system"
require "colorize"
require "toml"
require "yaml"
require "./status"
require "./log"
require "./format"
require "tallboy"


module Agent
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
      sleep 5.seconds
      payload = Status.get_payload(config, log).to_msgpack
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
      payload = Status.get_payload(config, log)
      p payload
      # convert to msgpck binary
      payload_mp = payload.to_json.to_msgpack
      
      # convert back to hash
      v = JSON.parse(MessagePack.unpack(payload_mp).to_s)
      
      if payload.is_a?(Agent::Status::Payload)
        data = [] of Array(String | Colorize::Object(String))
        check_type = Hash(String, String).new
        check_type["cpu"] = "system"
        check_type["memory"] = "system"
        check_type["process"] = "process"

        ### cycle through Checks Hash and create array for output Table
        if payload.checks.is_a?(Hash)
          p "HASH"
          
          if payload.checks.has_key?("alert")
            payload.checks["alert"].each do | key, val |
              p key.colorize(:yellow)
              p val.colorize(:green)
              if val.is_a?(Hash)
                val.each do | k, v |
                  #p v
                  #p k.colorize(:cyan)
                  data << ["(#{key}) #{k}", v[0].to_s, v[1].to_s, "alert".colorize(:red), check_type[key]]
                end
              end
            end
          end # alert

          if payload.checks.has_key?("ok")
            payload.checks["ok"].each do | key, val |
              if val.is_a?(Hash)
                val.each do | k, v |
                  data << ["(#{key}) #{k}", v[0].to_s, v[1].to_s, "ok".colorize(:green), check_type[key]]
                end
              end
            end
          end # ok
        end # payload is hash
      end # if Payload
      #p data

      # generate output table
      table = Tallboy.table do
        columns do
          add "Service"
          add "Limit"
          add "Actual"
          add "Status"
          add "Type"
        end
        header
        if data

          rows data
        end
      end # table
      puts table.render(:markdown) 

    rescue error
      puts error.colorize(:red)
      error.inspect_with_backtrace(STDOUT)
      exit 1
    end
  end # if status true


  
  #cpu = Hardware::CPU.new
  #PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
  #app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID
end # module
