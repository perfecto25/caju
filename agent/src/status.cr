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

    cpu_data = Cpu.get_cpu_info
    puts cpu_data
    status = {
      "hostname" => System.hostname,
      "uptime" => Sys.get_uptime,
      "cpu" => cpu_data
    }
    return status
    
   # puts typeof(cpu_data)
    #status = {"ok": "ok"}
     #"cpu_pct" => PID_STAT.cpu_usage!,
      #"mem" => { "actual" => Memory.sys_mem_info },
      #"uptime" => { "actual" => Sys.get_uptime }
    #}

   
    #return status
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
