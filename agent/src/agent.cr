require "hardware"

memory = Hardware::Memory.new
memory.used         # => 2731404
memory.percent.to_i # => 32

cpu = Hardware::CPU.new
pid_stat = Hardware::PID.new.stat               # Default is Process.pid
#app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID

loop do
  sleep 1
  puts cpu.usage!.to_i          # => 17
  puts pid_stat.cpu_usage!      # => 1.5
#  p app_stat.cpu_usage!.to_i # => 4
end
