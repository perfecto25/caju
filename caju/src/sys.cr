require "json"
require "system"

module Caju::Sys
  extend self

  def b_to_gb(bytes)
    return bytes / 1_073_741_824.0
  end

  # Structure to hold system information metadata
  struct Info
    include JSON::Serializable
    property hostname : String
    property cpu_count : Int64
    property cpu_load_average : Hash(String, Float64)
    property cpu_usage : Int32
    property cpu_details : Hash(String, String)
    #property disk_usage : Hash(String, Hash(String, UInt64))
    #property mounts : Array(String)
    property manufacturer : String
    property model : String
    property process_memory : Hash(String, UInt64)
    property system_memory : Hash(String, UInt64)

    def initialize
      @hostname = get_hostname
      @cpu_count = System.cpu_count
      @cpu_load_average = get_cpu_load_average
      @cpu_usage = get_cpu_usage
      @cpu_details = get_cpu_details
     ## @disk_usage = get_disk_usage
     ## @mounts = get_mounts
     @manufacturer, @model = get_hardware_info
     @process_memory = get_process_memory
     @system_memory = get_system_memory

    end

    # Get hostname
    private def get_hostname : String
      System.hostname || `hostname`.strip
    rescue
      "Unknown"
    end

    # # Get total memory size in bytes
    # private def get_memory_size : UInt64
    #   {% if flag?(:linux) %}
    #     File.read_lines("/proc/meminfo").each do |line|
    #       if line.starts_with?("MemTotal")
    #         return (line.split[1].to_u64 * 1024) # Convert kB to bytes
    #       end
    #     end
    #   {% end %}
    #   0_u64
    # end

    # # Get swap size in bytes
    # private def get_swap_size : UInt64
    #   {% if flag?(:linux) %}
    #     File.read_lines("/proc/meminfo").each do |line|
    #       if line.starts_with?("SwapTotal")
    #         return (line.split[1].to_u64 * 1024) # Convert kB to bytes
    #       end
    #     end
    #   {% end %}
    #   0_u64
    # end

    # Get disk usage for mounted filesystems
    private def get_disk_usage : Hash(String, Hash(String, UInt64))
      usage = Hash(String, Hash(String, UInt64)).new
      {% if flag?(:linux) %}
        `df -B1`.each_line.skip(1).each do |line|
          parts = line.split
          if parts.size >= 6
            mount_point = parts[5]
            usage[mount_point] = {
              "total" => parts[1].to_u64,
              "used" => parts[2].to_u64,
              "free" => parts[3].to_u64,
            }
          end
        end
      {% end %}
      usage
    end

    # Get mount points
    private def get_mounts : Array(String)
      mounts = [] of String
      {% if flag?(:linux) %}
        File.read_lines("/proc/mounts").each do |line|
          parts = line.split
          mounts << parts[1] if parts.size >= 2
        end
      {% end %}
      mounts
    end # get_mounts

    # Get hardware information (manufacturer and model)
    private def get_hardware_info : Tuple(String, String)
      manufacturer = "Unknown"
      model = "Unknown"
      {% if flag?(:linux) %}
        begin
          manufacturer = File.read("/sys/devices/virtual/dmi/id/sys_vendor").strip rescue "Unknown"
          model = File.read("/sys/devices/virtual/dmi/id/product_name").strip rescue "Unknown"
        rescue
          # Fallback if DMI info is not available
        end
      {% end %}
      {manufacturer, model}
    end # get_hardware_info

    # Get process memory usage (RSS and VSS) in bytes
    private def get_process_memory : Hash(String, UInt64)
      memory = Hash(String, UInt64).new
      memory["rss"] = 0_u64
      memory["vss"] = 0_u64
      {% if flag?(:linux) %}
        begin
          File.read_lines("/proc/self/status").each do |line|
            if line.starts_with?("VmRSS")
              memory["rss"] = line.split[1].to_u64 * 1024 # Convert kB to bytes
            elsif line.starts_with?("VmSize")
              memory["vss"] = line.split[1].to_u64 * 1024 # Convert kB to bytes
            end
          end
        rescue
          # Fallback if /proc/self/status is inaccessible
        end
      {% end %}
      memory
    end # get_process_memory

    # Get system memory usage (used, cached, available) in bytes
    private def get_system_memory : Hash(String, UInt64)
      memory = Hash(String, UInt64).new
      memory["used"] = 0_u64
      memory["cached"] = 0_u64
      memory["available"] = 0_u64
      memory["swap_total"] = 0_u64
      memory["swap_used"] = 0_u64
      memory["swap_free"] = 0_u64
      {% if flag?(:linux) %}
        begin
          mem_total = 0_u64
          mem_free = 0_u64
          buffers = 0_u64
          cached = 0_u64
          mem_available = 0_u64
          swap_total = 0_u64
          swap_free = 0_u64
          swap_used = 0_u64

          File.read_lines("/proc/meminfo").each do |line|
            parts = line.split
            next unless parts.size >= 2
#            value = parts[1].to_u64 * 1024 # Convert kB to bytes
            case parts[0]
              when "MemTotal:" then mem_total = parts[1].to_u64 * 1024
              when "MemFree:" then mem_free = parts[1].to_u64 * 1024
              when "Buffers:" then buffers = parts[1].to_u64 * 1024
              when "Cached:" then cached = parts[1].to_u64 * 1024
              when "MemAvailable:" then mem_available = parts[1].to_u64 * 1024
              when "SwapTotal:" then memory["swap_total"] = parts[1].to_u64 * 1024
              when "SwapFree:" then memory["swap_free"] = parts[1].to_u64 * 1024
            end
          end
          memory["size"] = mem_total
          memory["used"] = mem_total - mem_free - buffers - cached
          memory["cached"] = cached
          memory["available"] = mem_available
          memory["swap_used"] = memory["swap_total"] - memory["swap_free"]
        rescue
          # Fallback if /proc/meminfo is inaccessible
        end
      {% end %}
      memory
    end # get_system_memory

    # Get CPU load averages (1, 5, 15 minutes)
    private def get_cpu_load_average : Hash(String, Float64)
      load_avg = Hash(String, Float64).new
      load_avg["1min"] = 0.0
      load_avg["5min"] = 0.0
      load_avg["15min"] = 0.0
      {% if flag?(:linux) %}
        begin
          line = File.read("/proc/loadavg").split
          if line.size >= 3
            load_avg["1min"] = line[0].to_f64
            load_avg["5min"] = line[1].to_f64
            load_avg["15min"] = line[2].to_f64
          end
        rescue
          # Fallback if /proc/loadavg is inaccessible
        end
      {% end %}
      load_avg
    end # get_cpu_load_average

    private def get_cpu_usage : Int32
      ## stat /proc/stat for total CPU usage as %
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
        sleep 1.second
      end
      return percent.round(2).to_i32
      raise "Failed to get CPU usage"
    end # get_cpu_usage

    private def get_cpu_details : Hash(String, String)
      cpu_make = {} of String => String
      File.read("/proc/cpuinfo").each_line do |line|
        if line.includes?(":")
          key, value = line.split(":", 2).map(&.strip)
          cpu_make[key] = value
        end
      end
      return cpu_make
    end # get_cpu_details
  end

end # Module
