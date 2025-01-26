
module Agent::Sys
  extend self

  def get_uptime
    seconds = File.read("/proc/uptime").split.first.to_f
    days, remainder = seconds.divmod(86400)
    hours, remainder = remainder.divmod(3600)
    minutes, seconds = remainder.divmod(60)
    parts = [] of String
    parts << "#{days.to_i} days" if days > 0
    parts << "#{hours.to_i} hours" if hours > 0
    parts << "#{minutes.to_i} minutes" if minutes > 0
    parts << "#{seconds.to_i} seconds"
    parts.join(", ")
    return parts
  end
end
