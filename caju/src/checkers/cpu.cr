  def cpu_checker(report, ctype, sysinfo)
    ## Check CPU expected vs actual

    # CPU USAGE
    if ctype.as_h.has_key?("usage")
      if ctype["usage"].as_h.has_key?("pct")
        flag = 0
        expected = ctype["usage"]["pct"].as_i64.to_i32
        actual = sysinfo.cpu_usage.to_i32
        if actual >= expected
          flag = 1
        else
          flag = 0
        end
        report = {"cpu" => { "usage" => {"flag" => flag, "expected" => expected, "actual" => actual}}}
      end
    end # CPU USAGE

    # CPU LOADAVG
    if ctype.as_h.has_key?("loadavg")
      if ctype["loadavg"].as_h.has_key?("1")
        p "loadvg 1"
      end
      if ctype["loadavg"].as_h.has_key?("5")
        p "loadvg 5"
      end
      if ctype["loadavg"].as_h.has_key?("15")
        p "loadvg 15"
      end
    end # CPU LOADAVG

    return report
  end # cpu_checker
