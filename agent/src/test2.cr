require "json"
require "toml"

def toml_to_json(toml_any)
  case toml_any
  when Hash(String, TOML::Any)
    # Convert hash/table to JSON::Any hash
    toml_any.each_with_object(JSON::Any.new({} of String => JSON::Any)) do |(k, v), hash|
      hash.as_h[k] = toml_to_json(v)
    end
  when Array(TOML::Any)
    # Convert array to JSON::Any array
    toml_any.map { |item| toml_to_json(item) }
  when String, Int32, Int64, Float32, Float64, Bool, Nil
    # Convert simple types directly
    JSON::Any.new(toml_any)
  else
    p "ERROR"
    p typeof(toml_any.class)
    #raise "Unsupported TOML type: #{toml_any.class}"
  end
end


json_data = Hash(String, JSON::Any).new

# Adding a simple key-value pair
json_data["name"] = JSON::Any.new("John Doe")

p json_data
p json_data.to_json

begin
  config_data = TOML.parse(File.read("config.toml")).as(Hash)
rescue exception
  abort "unable to parse TOML: #{exception}", 1
end

p config_data
p typeof(config_data)
#cfg = toml_to_json(config_data)
#json_data["config"] = cfg
#p json_data