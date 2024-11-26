require "hardware"
require "http/client"
require "option_parser"
require "system"
require "toml"
require "./sys/memory"
require "./sys/cpu"
require "./sys/sys"

module Caju::Status
  extend self

  struct Data
    include MessagePack::Serializable
    property hostname, cpu_pct, loadavg
    def initialize(
      @hostname : String, 
      @cpu_pct : Int32, 
      @cpu_loadavg : Array(Float64),
      @cpu_model : String,
      @cpu_cache : String,
      @cpu_cores : Int32 | String,
      )
    end

    def to_h
      {
        "hostname" => @hostname, 
        "cpu" => {
          "pct" => @cpu_pct, 
          "loadvg" => @cpu_loadavg,
          "model" => @cpu_model,
          "cache" => @cpu_cache,
          "cores" => @cpu_cores
        }
      }
    end
  end

  def get_actual(config)
    data = Data.new(
      System.hostname.to_s, 
      Cpu.get_cpu_pct, 
      Cpu.get_load_avg, 
      Cpu.get_cpu_make["model name"]? || "Unknown",
      Cpu.get_cpu_make["cache size"]? || "Unknown",
      Cpu.get_cpu_make["cpu cores"].to_i? || 0,

      )

    return data.to_h
  end # get_status


  # check if actual value is over the limit of config
  def check_actual(config, actual)
    #result = {} of String | Int32 | Float64
    
    if config.has_key?("cpu")
      
      if config["cpu"].as_h.has_key?("limit")
        p config["cpu"]["limit"].as_i
        #p typeof(config["cpu"]["limit"])
        cpu = actual["cpu"]
        p cpu["cpu_pct"]
        p typeof(cpu)
        #p typeof(actual["cpu"]["cpu_pct"])
        #if config["cpu"]["limit"].as_i >= actual["cpu"]["cpu_pct"].as_i
        #  puts "CPU limit above configured threshold"
        #end
      end

      
    end
    # config.each do | key, val |
    #   puts key.to_s + ":" + val.to_s
    # end
  end

end # module
