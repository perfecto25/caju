def compare(ctype, cname, expected, actual)
  flag = 0
  p "ctype=#{ctype}, cname=#{cname}, expected=#{expected}, actual=#{actual}"
  if actual >= expected
    flag = 1
  else
    flag = 0
  end
  return {ctype => { cname => {"flag" => flag, "expected" => expected, "actual" => actual}}}
end

def cpu_checker(report, ctype, sysinfo)
    ## Check CPU expected vs actual
    # CPU USAGE
    if ctype.as_h.has_key?("usage")
      if ctype["usage"].as_h.has_key?("pct")
        report = compare("cpu", "usage.pct", ctype["usage"]["pct"].as_i64.to_i32, sysinfo.cpu_usage.to_i32)
      end
    end # CPU USAGE

    # CPU LOADAVG
    if ctype.as_h.has_key?("loadavg")
      # >>> add checks if array, if has 3 elements if can cast to float64
      report = compare("cpu", "loadavg.1",ctype["loadavg"][0].as_i64.to_f64, sysinfo.cpu_load_average["1min"].to_f64)
      report = compare("cpu", "loadavg.5",ctype["loadavg"][1].as_i64.to_f64, sysinfo.cpu_load_average["5min"].to_f64)
    end # CPU LOADAVG

    return report
  end # cpu_checker
