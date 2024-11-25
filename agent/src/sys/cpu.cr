
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
      load_avg = [avg[0], avg[1], avg[2]]
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



  class Meta 
    include JSON::Serializable
    property cpu_count : Int32 | Nil
    property model : String | Nil
    property cache : String | Nil
  end
  
  class Data
    include JSON::Serializable
    property actual : String | Int32
    property meta : Meta?
  end


  struct Body
  def get_cpu_info
    percent = 0
    #cpu_info = Hash(String, String | Int64 | Float64 | Hash(String, Float64) | Hash(String, Int64) | Hash(String, Int32)).new
    # 
    # 

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

    # actual cpu % or load avg
    
    
    #cpu_info = Meta.from_json(%( {"cpu_count": #{System.cpu_count}} ))
   # puts cpu_info
   
   # cpu_info = Data.new(actual: 33, meta: Meta.new(cpu_count: 13, cache: "300mb"))
    cpu_info = Data.from_json(%( 
      {
        "actual": #{percent.round(2).to_i64},
        "meta": {"cpu_count":  #{System.cpu_count}}
      }
    ))
    puts cpu_info.actual
    puts cpu_info.meta.cpu_count || "nil value xx"
   
    #puts cpu_info.meta["cpu_count"]
    #puts cpu_info.meta.cpu_count
    # immutable meta params
    #cpu_info["meta"].as(Hash)
    #puts cpu_info

    #cpu_info["actual"] = percent.round(2).to_i64
    # cpu_info["meta"]["cpu_count"] = System.cpu_count
    # cpu_make = get_cpu_make
    # cpu_info["meta"]["model"] = cpu_make["model name"]? || "Unknown"
    # cpu_info["meta"]["cache"] = cpu_make["cache size"]? || "Unknown"
    # cpu_info["meta"]["cores"] = cpu_make["cpu cores"]? || "Unknown"

    # loadavg = get_load_avg
    # cpu_info["actual"]["loadvg"] = { "1m" => loadavg[0].round(2), "5m" => loadavg[1].round(2), "15m" => loadavg[2].round(2) }
    
    return cpu_info
    
    raise "Failed to get CPU usage"
  end





end # module

