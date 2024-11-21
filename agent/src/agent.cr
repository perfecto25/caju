require "hardware"
require "msgpack"

io = IO::Memory.new 
memory = Hardware::Memory.new
memory.used         # => 2731404
memory.percent.to_i # => 32

CPU = Hardware::CPU.new
PID_STAT = Hardware::PID.new.stat               # Default is Process.pid
#app_stat = Hardware::PID.new("terminator").stat # Take the first matching PID


class Payload
  include MessagePack::Serializable
  property name : String
  property cpu : Int32
  property cpu_pct : Float64
end

loop do
  sleep 1
  #payload = Payload.to_msgpack({"cpu" => CPU.usage!.to_i, "cpu_pct" => PID_STAT.cpu_usage!})
  
  encoded = MessagePack.pack({"name" => "JO", "age" => 10})
  
  puts encoded
  decoded = MessagePack.unpack(encoded)
  puts decoded
  
  payload = Payload.from_msgpack({cpu: CPU.usage!.to_i, cpu_pct: PID_STAT.cpu_usage!, name: "Joe"}.to_msgpack)
  puts payload

  puts payload.cpu
  puts payload.cpu_pct
  # payload.cpu = 300
  # payload.name = "Frank"
  # payload = Payload.from_msgpack(payload.to_msgpack)
  # puts payload
  # #puts Payload.from_msgpack(payload)
  #puts payload.from_msgpack
  #puts cpu.usage!.to_i          # => 17
  #puts pid_stat.cpu_usage!      # => 1.5
#  p app_stat.cpu_usage!.to_i # => 4
end
