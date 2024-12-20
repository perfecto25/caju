
require "system"
require "lib_c"
require "json"
require ".././log"

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


  def check_cpu_limit_status(config, actual, result, log)
    log = ::Log.for("Caju::CPU::check_cpu_limit_status")
    
    return result if ! (config.dig?("check", "cpu", "limit") && actual.dig?("cpu", "pct"))
    result["alert"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["alert"].has_key?("cpu")
    result["ok"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["ok"].has_key?("cpu")
    
    cfg_val = config.dig?("check", "cpu", "limit")
    log.error {cfg_val}
    actual_val = actual.dig?("cpu", "pct")
    if !cfg_val.nil? && !actual_val.nil?
      if actual_val.is_a?(Int32)
        # create ALERT if actual value is over threshold of config value
        if cfg_val.as_i <= actual_val
          result["alert"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] 
        else
          # create OK if actual value is below threshold of config value
          result["ok"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] 
        end
      end
    end 
    
    return result
  end # check_cpu_limit_status


  def check_cpu_loadavg_status(config, actual, result, log)
    log = ::Log.for("Caju::CPU::check_cpu_loadavg_status")

    return result if ! config.dig?("check", "cpu", "loadavg") || ! actual.dig?("cpu", "loadavg")
    result["alert"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["alert"].has_key?("cpu")
    result["ok"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["ok"].has_key?("cpu")

    cfg_val = config.dig?("check", "cpu", "loadavg")
    actual_val = actual.dig?("cpu", "loadavg")

    if !cfg_val.nil? && !actual_val.nil? && actual_val.is_a?(Array(Float64))
      ["min1", "min5", "min15"].each_with_index do |value, idx|
        if cfg_val.as_h.has_key?(value) && actual_val.size == 3
          if cfg_val[value].as_f <= actual_val[idx]
            result["alert"]["cpu"]["loadavg.#{value}"] = [cfg_val[value].as_f, actual_val[idx].to_f64]
          else 
            result["ok"]["cpu"]["loadavg.#{value}"] = [cfg_val[value].as_f, actual_val[idx].to_f64]
          end
        end
      end
    end 
    return result
  end # check_cpu_limit_status

end # module

