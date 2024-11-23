require "http/server"
require "msgpack"

module Engine
  extend self
  server = HTTP::Server.new do |context|
    if context.request.method == "POST" && context.request.headers["Content-Type"]? == "application/msgpack"
      # Read the MessagePack data from the request body
      input_data = MessagePack.unpack(context.request.body.not_nil!)
      # Process the input data (in this example, we're just logging it)
      puts "Received data: #{input_data}"

      # Prepare the "OK" response in MessagePack format
      response_data = {"status" => "OK"}
      response_msgpack = response_data.to_msgpack
    
      # Set the response headers and body
      context.response.content_type = "application/msgpack"
      context.response.write(response_msgpack)
    else
      # If the request is not a POST with MessagePack, return an error
      context.response.status_code = 400
      context.response.print "Bad Request: Expected POST with MessagePack"
    end
  end 

  address = server.bind_tcp 8090 
  puts "listeining on #{address}"
  server.listen

end # module