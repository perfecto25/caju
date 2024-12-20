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
          "pct" => @cpu_pct.to_i, 
          "loadavg" => @cpu_loadavg,
          "model" => @cpu_model,
          "cache" => @cpu_cache,
          "cores" => @cpu_cores
        }
      }
    end
  end

  def get_actual(config, log)
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


  # check if actual value is over the limit defined in config
  def check_status(config, actual, log)

    result = Hash(String, Hash(String, Hash(String, Array(Int32) | Array(Float64)))).new
    result["alert"] = Hash(String, Hash(String, Array(Int32) | Array(Float64))).new
    result["ok"] = Hash(String, Hash(String, Array(Int32) | Array(Float64))).new

    #if ! config.as_h.has_key?("check")
    if ! config.has_key?("check")
      return "No checks defined in config file"
    end

    result = Cpu.check_cpu_limit_status(config, actual, result, log)
    result = Cpu.check_cpu_loadavg_status(config, actual, result, log)
    log.info { "test 2" }
    #result = Cpu.check_cpu_loadavg_status(config, actual, result)
    log.info { result }
      


  end # def check_actual


end # module
