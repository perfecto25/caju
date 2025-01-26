require "hardware"
require "colorize"
require ".././log"

module Agent::Memory
  extend self 

  def get_mem_info
    log = ::Log.for("Caju::MEM::get_mem_info")
    begin
      mem_info = Hash(String, Int64).new
      File.each_line("/proc/meminfo") do |line|
        key, value = line.match(/(.*)?:\s+?(\d+)/).not_nil!.to_s.split
        mem_info[key] = value.to_i64
      end
      mem_info["pct_used"] = (((mem_info["MemTotal:"] - mem_info["MemAvailable:"]) / mem_info["MemTotal:"]) * 100).to_i
      mem_info["gb_used"] = ((mem_info["MemTotal:"] - mem_info["MemAvailable:"]) / 1000000).to_i
    rescue exception
      log.error { exception.colorize(:red) }
    end
    
    return mem_info
  end

  def get_status(config, payload, log)
    puts "mem status" 
  end
end # module