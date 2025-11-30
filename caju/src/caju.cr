require "option_parser"
require "toml"
require "msgpack"
require "colorize"
require "hardware"
require "tallboy"
require "log"
#require "./log"
require "./sys"
require "./status"

module Caju
  extend self

  Log = ::Log.for("Caju")

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
    #log = init_log(config)
    #log.info { config }
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
  Log.info { "INFO" }
    begin
      sysinfo = Caju::Sys::Info.new
      columns = Nil
      row_data = [] of Array(String)
      row_data << ["hostname", sysinfo.hostname.to_s]
      row_data << ["model", sysinfo.model.to_s]
      row_data << ["manufacturer", sysinfo.manufacturer.to_s]
      row_data << ["CPU count", sysinfo.cpu_count.to_s]
      row_data << ["CPU vendor", sysinfo.cpu_details["vendor_id"].to_s]
      row_data << ["memory", Caju::Sys.b_to_gb(sysinfo.system_memory["size"]).round(3).to_s + " GB"]
      table = Tallboy.table do
        header do
          cell "Caju sysinfo", span: 2
        end
        if row_data
          row_data.each do |r|
            row r
          end
        end
      end # table
      puts table.render
    rescue exception
      puts exception.colorize(:red)
      exception.inspect_with_backtrace(STDOUT)
      exit 1
    end
  end # if

  # if status return status
  if status == true && daemon == false
    begin
      sysinfo = Caju::Sys::Info.new
      #puts typeof(config)
      #puts sysinfo
#      puts sys_info.to_json
      status = Caju::Status::Checker.new(config.not_nil!, sysinfo)
      p status
    end
  end


end # Module
