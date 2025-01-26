require "json"

class Payload
  #include MessagePack::Serializable
  include JSON::Serializable
  
  @[JSON::Field(key: "meta")]
  property meta #: Hash(String, Int32 | String) | Nil
  @[JSON::Field(key: "stats")]
  property stats #: Hash(String, Hash(String, Array(Float64) | Int32 | Int64 | String))
  @[JSON::Field(key: "checks")]
  property checks #: Hash(String, Hash(String, Hash(String, Array(Float64) | String)))

  def initialize(*, 
    meta : Hash(String, Int32 | String) | Nil, 
    stats : Hash(String, Hash(String, Array(Float64) | Int32 | Int64 | String)) | Nil, 
    checks : Hash(String, Hash(String, Hash(String, Array(Float64) | String))) | Nil)

    @meta = meta
    @stats = stats
    @checks = checks

  end
end

payload = Payload.new(meta: nil, stats: nil, checks: nil)
payload.meta = "test"
p payload.to_json
