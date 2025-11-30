  def check_cpu_limit_status(config, payload, log)
    log = ::Log.for("Caju::CPU::check_cpu_limit_status")

    return payload if ! (config.dig?("check", "cpu", "limit") && payload.stats.dig?("cpu", "pct"))

    cfg_val = config.dig?("check", "cpu", "limit", "pct")
    actual_val = payload.stats.dig?("cpu", "pct")

    begin
      if !cfg_val.nil? && !actual_val.nil?
        if actual_val.is_a?(Int32)
          # create ALERT if actual value is over threshold of config value
          if cfg_val.as_i <= actual_val
            payload.checks["alert"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] #.join(", ")
          else
            # create OK if actual value is below threshold of config value
            payload.checks["ok"]["cpu"]["limit"] = [cfg_val.as_i, actual_val] #.join(", ")
          end
        end
      end
    rescue exception
      log.error { exception.colorize(:red) }
    end

    return payload
  end # check_cpu_limit_status
