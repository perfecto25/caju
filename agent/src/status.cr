require "hardware"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "json"
require "./stats/memory"
require "./stats/cpu"
require "./stats/sys"

module Agent::Status
  extend self

  class Payload
    include MessagePack::Serializable
    include JSON::Serializable
    
    @[JSON::Field(key: "meta")]
    property meta : Hash(String, Int32 | String | Array(String))
    @[JSON::Field(key: "stats")]
    property stats : Hash(String, Hash(String, Array(Float64) | Int32) | Hash(String, Int64) | Nil)
    @[JSON::Field(key: "checks")]
    property checks : Hash(String, Hash(String, Hash(String, Array(Float64) | Array(Int32) | String)))

    def initialize(@meta, @stats, @checks)
    end
  end



  # gets all actual values as defined from Config
  # checks if actual value is over the limit defined in config
  def compare_status(config, payload, log)
    if ! config.has_key?("check")
      return "No checks defined in config file"
    end


    Cpu.get_status(config, payload, log)
    Memory.get_status(config, payload, log)
    
    return payload
  end # def compare_status



  # Payload contains full return data of all stats and check results
  def get_payload(config, log)
    payload = Payload.new(
      { # static host metadata
        "hostname" => System.hostname.to_s,
        "cpu_model" => Cpu.get_cpu_make["model name"]? || "Unknown",
        "cpu_cache" => Cpu.get_cpu_make["cache size"]? || "Unknown",
        "cpu_cores" =>  Cpu.get_cpu_make["cpu cores"].to_i? || 0,
        "uptime" => Sys.get_uptime
      },
      { # active stats
        "cpu" => {
          "loadavg" => Cpu.get_load_avg,
          "pct" => Cpu.get_cpu_pct
        },
        "memory" => Memory.get_mem_info
      },
      {
        "alert" => {} of String => Hash(String, String | Array(Float64) | Array(Int32)),
        "ok" => {} of String => Hash(String, String | Array(Float64) | Array(Int32)),
      }
    )
    compare_status(config, payload, log)
    
  end # get_payload



end # module
