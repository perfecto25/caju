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

  def get_actual(config)
    status = {
      "hostname" => System.hostname,
      "cpu" => Cpu.get_cpu_info,
    #"cpu_pct" => PID_STAT.cpu_usage!,
      #"mem" => { "actual" => Memory.sys_mem_info },
      #"uptime" => { "actual" => Sys.get_uptime }
    }

    return status
   # "mem_pct" => mem[1]  
  end # get_status


  # check if actual value is over the limit of config
  def check_actual(config, actual)
    #result = {} of String | Int32 | Float64
    
    if config.has_key?("cpu")
      puts config["cpu"]
    end
    # config.each do | key, val |
    #   puts key.to_s + ":" + val.to_s
    # end
  end

end # module
