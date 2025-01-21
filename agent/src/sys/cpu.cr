
require "system"
require "lib_c"
require "colorize"
require "json"
require ".././log"

module Agent::Cpu
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

  ## generate Hash for Status return
  def create_status_hash(result)
    if ! result["alert"].has_key?("system")
      result["alert"]["system"] = Hash(String, Array(Int32) | Array(Float64)).new
    end
    if ! result["ok"].has_key?("system")
      result["ok"]["system"] = Hash(String, Array(Int32) | Array(Float64)).new
    end
    return result
  end

  def check_cpu_limit_status(config, payload, log)
    log = ::Log.for("Caju::CPU::check_cpu_limit_status")

    return payload if ! (config.dig?("check", "cpu", "limit") && payload.stats.dig?("cpu", "pct"))

    cfg_val = config.dig?("check", "cpu", "limit", "pct")
    actual_val = payload.stats.dig?("cpu", "pct")

    begin
      if !cfg_val.nil? && !actual_val.nil?
        if actual_val.is_a?(Int32)
          # create ALERT if actual value is over threshold of config value
          if cfg_val.as_i <= actual_val
            payload.checks["alert"]["cpu"]["limit"] = [cfg_val.as_i, actual_val].join(", ")
          else
            # create OK if actual value is below threshold of config value
            payload.checks["ok"]["cpu"]["limit"] = [cfg_val.as_i, actual_val].join(", ")
          end
        end
      end
    rescue exception
      log.error { exception.colorize(:red) }
    end
    
    return payload
  end # check_cpu_limit_status


  def check_cpu_loadavg_status(config, actual, result, log)
    log = ::Log.for("Caju::CPU::check_cpu_loadavg_status")

    return result if !config.dig?("check", "cpu", "loadavg") || !actual.dig?("cpu", "loadavg")
    result["alert"]["system"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["alert"]["system"].has_key?("cpu")
    result["ok"]["system"]["cpu"] = Hash(String, Array(Int32) | Array(Float64)).new if ! result["ok"]["system"].has_key?("cpu")

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
  end # check_cpu_loadavg_status

  # return all CPU statuses
  def get_status(config, payload, log)
    
    ### create Alert and OK keys
    if ! payload.checks.dig?("alert", "cpu")
      payload.checks["alert"]["cpu"] = {} of String => String
    end

    if ! payload.checks.dig?("ok", "cpu")
      payload.checks["ok"]["cpu"] = {} of String => String
    end

    ### get Stats
    payload.stats["cpu"]["pct"] = get_cpu_pct

    check_cpu_limit_status(config, payload, log)
    return payload

  end


end # module

