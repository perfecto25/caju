require "msgpack"
require "toml"


class Meta
  include MessagePack::Serializable

  @[MessagePack::Field(key: "hostname")]
  property hostname : String

  @[MessagePack::Field(key: "model")]
  property model : String

  def initialize(@hostname : String, @model : String)
  end
end

class Config
  include MessagePack::Serializable
  @[MessagePack::Field(key: "config")]
  property config : Hash(String, TOML::Any)
  def initialize(@config : Hash(String, TOML::Any))
  end
end

class Payload
  include MessagePack::Serializable

  @[MessagePack::Field(key: "config")]
  property config : Config

  @[MessagePack::Field(key: "meta")]
  property meta : Meta
  #@[MessagePack::Field(key: "data")]
  #property data : Hash(String, MessagePack::Any)

  def initialize(@config : Config, @meta : Meta)
  end
end




begin
  config_data = TOML.parse(File.read("config.toml")).as(Hash)
rescue exception
  abort "unable to parse TOML: #{exception}", 1
end

p config_data
p typeof(config_data)

meta = Meta.new("qbtch4", "poweredge640")
cfg = Config.new(config_data.as(Hash))
payload = Payload.new(cfg, meta)


p payload.meta.hostname

msgpack_data = payload.to_msgpack
p msgpack_data

deserialized = Payload.from_msgpack(msgpack_data)

p deserialized.meta.hostname

# class Config
#   include MessagePack::Serializable

#   @[MessagePack::Field(key: "name")]
#   property name : String

#   @[MessagePack::Field(key: "age")]
#   property age : Int32

#   @[MessagePack::Field(key: "address")]
#   property address : Address

#   def initialize(@name : String, @age : Int32, @address : Address)
#   end
# end


#response = Payload.new(user, "success", {"checks": "ok"}.to_msgpack)

# Serialize to MessagePack
#msgpack_data = response.to_msgpack
#p msgpack_data

#d_response = Payload.from_msgpack(msgpack_data)

#p d_response.user.address.street