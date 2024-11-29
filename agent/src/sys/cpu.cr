
require "system"
require "lib_c"
require "json"

module Caju::Cpu
  extend self



    # Define the libc function to get load averages
  lib LibC
    fun getloadavg(avg : Pointer(Float64), nelem : Int32) : Int32
  end

  def get_load_avg
    # Array to hold the load averages
    avg = Pointer(Float64).malloc(3)
    # Call the C function to get load averages
    if LibC.getloadavg(avg, 3) != -1
      load_avg = [avg[0].round(2), avg[1].round(2), avg[2].round(2)]
      return load_avg
    else
      raise "Failed to get load average"
    end
  end # get_load_avg

  def get_cpu_make
    cpu_make = {} of String => String
    File.read("/proc/cpuinfo").each_line do |line|
      if line.includes?(":")
        key, value = line.split(":", 2).map(&.strip)
        cpu_make[key] = value
      end
    end
    return cpu_make
  end

  def get_cpu_pct
    percent = 0
    prev_idle = prev_total = 0
    2.times do
      cpu = File.read("/proc/stat").lines.first.split[1..-1].map(&.to_f)
      idle = cpu[3]
      total = cpu.sum
      if prev_idle > 0 && prev_total > 0
        idle_delta = idle - prev_idle
        total_delta = total - prev_total
        percent = 100.0 * (1.0 - idle_delta / total_delta)
      end
      
      prev_idle = idle
      prev_total = total
      sleep 1
    end

    return percent.round(2).to_i32
    raise "Failed to get CPU usage"
  end # get_cpu_pct


  def check_status(config, actual, result)
    
    # CPU LIMIT
    if ! (config.dig?("check", "cpu", "limit") && actual.dig?("cpu", "pct"))
      return result
    end

    cfg_val = config.dig?("check", "cpu", "limit")
    actual_val = actual.dig?("cpu", "pct")
    if !cfg_val.nil? && !actual_val.nil?
      if actual_val.is_a?(Int32)

        # create ALERT if actual value is over threshold of config value
        if cfg_val.as_i <= actual_val
          if ! result["alert"].has_key?("cpu")
            result["alert"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new
          end
          result["alert"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] 

          # create OK if actual value is below threshold of config value
        else
          if ! result["ok"].has_key?("cpu")
            result["ok"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new
          end
          result["ok"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] 
        end
      end
    end 

    return result
  end # check_status


end # module

