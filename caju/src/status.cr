

module Caju::Status
  extend self
  struct Status
    property meta : Hash(String, (Hash(String, UInt64)|))