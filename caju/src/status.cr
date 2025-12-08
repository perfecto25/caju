require "json"
require "./sys"
require "log"
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
      report = nil
      checks = config["check"].as_h
      checks.each do | cname, ctype |
        ## CPU
        if cname == "cpu"
          if ctype.as_h.has_key?("usage")
            if ctype["usage"].as_h.has_key?("pct")
              flag = 0
              expected = ctype["usage"]["pct"].as_i64.to_i32
              actual = sysinfo.cpu_usage.to_i32
              if actual >= expected
                flag = 1
              else
                flag = 0
              end
              report = {"cpu" => { "usage" => {"flag" => flag, "expected" => expected, "actual" => actual}}}
            end
          end # usage pct
          if ctype.as_h.has_key?(loadav)
        end # CPU


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
