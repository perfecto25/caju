# agent

uses msgpack for data payload


pack Payload class > JSON > Msgpack

    data = actual.to_json.to_msgpack

unpack from msgpack

    payload = JSON.parse(MessagePack.unpack(data).to_s)
    
    p payload["meta"]


