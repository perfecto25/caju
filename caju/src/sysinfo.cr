require "json"
require "system"

module Caju::SysInfo
  extend self

  # Structure to hold system information metadata
  struct Sysinfo
    property hostname : String
    property cpu_count : Int64
    property cpu_load_average : Hash(String, Float64)
    property swap_size : UInt64
    property disk_usage : Hash(String, Hash(String, UInt64))
    property mounts : Array(String)
    property manufacturer : String
    property model : String
    property process_memory : Hash(String, UInt64)
    property system_memory : Hash(String, UInt64)
    property cpu_load_average : Hash(String, Float64)

    def initialize
      @hostname = get_hostname
      @cpu_count = System.cpu_count
      @swap_size = get_swap_size
      @disk_usage = get_disk_usage
      @mounts = get_mounts
      @manufacturer, @model = get_hardware_info
      @process_memory = get_process_memory
      @system_memory = get_system_memory
      @cpu_load_average = get_cpu_load_average
    end

    # Get hostname
    private def get_hostname : String
      System.hostname || `hostname`.strip
    rescue
      "Unknown"
    end

    # Get total memory size in bytes
    private def get_memory_size : UInt64
      {% if flag?(:linux) %}
        File.read_lines("/proc/meminfo").each do |line|
          if line.starts_with?("MemTotal")
            return (line.split[1].to_u64 * 1024) # Convert kB to bytes
          end
        end
      {% end %}
      0_u64
    end

    # Get swap size in bytes
    private def get_swap_size : UInt64
      {% if flag?(:linux) %}
        File.read_lines("/proc/meminfo").each do |line|
          if line.starts_with?("SwapTotal")
            return (line.split[1].to_u64 * 1024) # Convert kB to bytes
          end
        end
      {% end %}
      0_u64
    end

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
    end

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
    end

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
    end

    # Get system memory usage (used, cached, available) in bytes
    private def get_system_memory : Hash(String, UInt64)
      memory = Hash(String, UInt64).new
      memory["used"] = 0_u64
      memory["cached"] = 0_u64
      memory["available"] = 0_u64
      {% if flag?(:linux) %}
        begin
          mem_total = 0_u64
          mem_free = 0_u64
          buffers = 0_u64
          cached = 0_u64
          mem_available = 0_u64
          File.read_lines("/proc/meminfo").each do |line|
            parts = line.split
            next unless parts.size >= 2
            value = parts[1].to_u64 * 1024 # Convert kB to bytes
            case parts[0]
            when "MemTotal:" then mem_total = value
            when "MemFree:" then mem_free = value
            when "Buffers:" then buffers = value
            when "Cached:" then cached = value
            when "MemAvailable:" then mem_available = value
            end
          end
          memory["size"] = get_memory_size
          memory["used"] = mem_total - mem_free - buffers - cached
          memory["cached"] = cached
          memory["available"] = mem_available
        rescue
          # Fallback if /proc/meminfo is inaccessible
        end
      {% end %}
      memory
    end

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
    end

    # Convert to JSON
    def to_json(json : JSON::Builder)
      json.object do
        json.field "hostname", hostname
        json.field "cpu_count", cpu_count
        json.field "cpu_load_average", cpu_load_average
        json.field "swap_size_bytes", swap_size
        json.field "disk_usage", disk_usage
        json.field "mounts", mounts
        json.field "manufacturer", manufacturer
        json.field "model", model
        json.field "process_memory", process_memory
        json.field "system_memory", system_memory
      end
    end
  end

end # Module

