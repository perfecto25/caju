require "json"
require "./sys"
require "log"
require "./checkers/*"
#require "./log"

module Caju::Status
  extend self
  struct Checker
    include JSON::Serializable
    Log = ::Log.for("Caju::Status::Checker")
    property status : Hash(String, Hash(String, Hash(String, Int32))) | String | Nil

    def initialize(@config : Hash(String, TOML::Any), @sysinfo : Caju::Sys::Info)
      @status = get_status(config, sysinfo)
    end

    private def get_status(config, sysinfo)
      if ! config.has_key?("check")
        return "No checks defined in config file"
      end


      report = Hash(String, Hash(String, Hash(String, Int32))).new

      checks = config["check"].as_h
      checks.each do | cname, ctype |
        p "CHKS cname=#{cname}, ctype=#{ctype}"

        if cname == "cpu"
          # if report is nil then create new hash
          report["cpu"] ||= Hash(String, Hash(String, Int32)).new
          report = cpu_checker(report, ctype, sysinfo)
        end


      end # checks loop

      if ! report.nil?
        return report
      end

    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "status", status
      end
    end

  end # struct
end # module
