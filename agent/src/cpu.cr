
require "system"

module Caju::Cpu
  extend self

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
    cpu_info = Hash(String, Int64 | String).new
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

    cpu_info["pct_used"] = percent.round(2).to_i64
    cpu_info["cpu_count"] = System.cpu_count
    cpu_make = get_cpu_make
    cpu_info["model"] = cpu_make["model name"]? || "Unknown"
    cpu_info["cache"] = cpu_make["cache size"]? || "Unknown"
    cpu_info["cores"] = cpu_make["cpu cores"]? || "Unknown"
    
    return cpu_info
    
    raise "Failed to get CPU usage"
  end
end

