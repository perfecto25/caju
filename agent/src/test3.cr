require "msgpack"
require "toml"
require "json"
require "yaml"

class Meta
  include MessagePack::Serializable

  @[MessagePack::Field(key: "hostname")]
  property hostname : String

  @[MessagePack::Field(key: "model")]
  property model : String

  def initialize(@hostname, @model)
  end
end

class Config
  include MessagePack::Serializable
  @[MessagePack::Field(key: "config")]
  property config : Hash(String, TOML::Any) 
  def initialize(@config)
  end
end

class Payload
  include JSON::Serializable
  include MessagePack::Serializable
  
  @[JSON::Field(key: "config")]
  @[MessagePack::Field(key: "config")]
  property config : Hash(String, TOML::Any)

  @[JSON::Field(key: "meta")]
  @[MessagePack::Field(key: "meta")]
  property meta : Meta

  # Custom initialization for JSON serialization
  def initialize(@config : Hash(String, TOML::Any), @meta : Meta)
    @config = convert_toml_to_json_any(@config)
  end



begin
  config_data = TOML.parse(File.read("config.toml")).as(Hash)
rescue exception
  abort "unable to parse TOML: #{exception}", 1
end

p config_data
p typeof(config_data)


def toml_any_to_serializable(value : Hash(String, TOML::Any))
  case value
  when Hash
    value.transform_values { |v| toml_any_to_serializable(v) }
  when Array
    value.map { |v| toml_any_to_serializable(v) }
  when String, Int64, Float64, Bool, Time
    value
  else
    value.raw
  end
end

meta = Meta.new("qbtch4", "poweredge640")
cfg = Config.new(config_data)
payload = Payload.new(config_data, meta)
p typeof(payload.config["log"])
p payload.config["log"]["destination"]

json_string = payload.to_json
#msgpack_data = payload.to_msgpack

p payload.meta.hostname
#p payload.config["log"]
#p typeof(payload.config.config)
