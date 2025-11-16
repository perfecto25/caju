require "json"
require "./sys"
require "log"
#require "./log"

module Caju::Status
  extend self
  struct Checker

    Log = ::Log.for("Caju::Status::Checker")
   # paylod = {
   #   "filesystem.home": [0, "36", "50"]
   # }
    property status : Hash(String, Array(String | Int32))

    def initialize(@config : Hash(String, TOML::Any), @sysinfo : Caju::Sys::Info)
      @status = get_status(config, sysinfo)
    end

    private def get_status(config, sysinfo)
      Log.warn { "Runnign STATUS"}
      if ! config.has_key?("check")
        return "No checks defined in config file"
      end
      return {"test" => [0, "23"]}
    end

    def to_json(json : JSON::Builder)
      json.object do
        json.field "status", status
      end
    end

  end # struct
end # module
