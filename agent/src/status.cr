require "hardware"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "json"
require "./sys/memory"
require "./sys/cpu"
require "./sys/sys"

module Agent::Status
  extend self

  class Payload
    include MessagePack::Serializable
    include JSON::Serializable
    
    @[JSON::Field(key: "meta")]
    property meta : Hash(String, Int32 | String) | Nil
    @[JSON::Field(key: "stats")]
    property stats : Hash(String, Hash(String, Array(Float64) | Int32 | String))
    @[JSON::Field(key: "checks")]
    property checks : Hash(String, Hash(String, Hash(String,  String)))

    def initialize(@meta, @stats, @checks)
    end
  end



  ### get all actual values as defined from Config
  ### check if actual value is over the limit defined in config
  def compare_status(config, payload, log)
    if ! config.has_key?("check")
      return "No checks defined in config file"
    end

    Cpu.get_status(config, payload, log)
    #result = Cpu.check_cpu_limit_status(config, actual, result, log)
    #result = Cpu.check_cpu_loadavg_status(config, actual, result, log)
    return payload
  end # def compare_status




  def get_payload(config, log)
    payload = Payload.new(
      { 
        "hostname" => System.hostname.to_s,
        "cpu_model" => Cpu.get_cpu_make["model name"]? || "Unknown",
        "cpu_cache" => Cpu.get_cpu_make["cache size"]? || "Unknown",
        "cpu_cores" =>  Cpu.get_cpu_make["cpu cores"].to_i? || 0,
      },
      {
        "cpu" => {} of String => Array(Float64) | Int32 | String
      },
      {
        "alert" => {} of String => Hash(String, String),
        "ok" => {} of String => Hash(String, String),
      }
    )
    compare_status(config, payload, log)
    return payload
  end # get_payload



end # module
