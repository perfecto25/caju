
require "system"
require "lib_c"
require "json"

module Caju::Cpu
  extend self

  # returner struct
  struct Data
    include JSON::Serializable
    struct Meta # immutable host properties
      include JSON::Serializable
      property cpu_count : Int32
      property model : String 
      property cache : String
      property cores : Int32 | String
      def initialize(@cpu_count, @model, @cache, @cores)
      end
    end
    
    # mutable host properties
    property cpu_pct : Int32
    property loadavg : Array(Float32)
    property meta : Meta
    def initialize(@cpu_pct, @loadavg, @meta)
    end
  end

    # Define the libc function to get load averages
  lib LibC
    fun getloadavg(avg : Pointer(Float64), nelem : Int32) : Int32
  end

  def get_load_avg
    # Array to hold the load averages
    avg = Pointer(Float64).malloc(3)
    # Call the C function to get load averages
    if LibC.getloadavg(avg, 3) != -1
      load_avg = [avg[0].to_f32.round(2), avg[1].to_f32.round(2), avg[2].to_f32.round(2)]
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

  def get_cpu_info
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

    cpu_make = get_cpu_make
    loadavg = get_load_avg

    data = Data.new(
      percent.to_i32.round(2),
      loadavg,
      Data::Meta.new(
        System.cpu_count.to_i32, 
        cpu_make["model name"]? || "Unknown",
        cpu_make["cache size"]? || "Unknown",
        cpu_make["cpu cores"].to_i? || "Unknown"
      )
    )
    ret = { 
        "cpu_pct" => percent.to_i32.round(2),
        "loadavg" => get_load_avg,
        "meta" => { 
          "cpu_count" => System.cpu_count.to_i32
        } 
      }
      
    return ret

    raise "Failed to get CPU usage"
  end





end # module

