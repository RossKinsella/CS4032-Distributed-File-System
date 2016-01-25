def get_message_param message, param
  param_start = message.index param
  param_end = -1

  if message[param_start..-1].include? ","
    param_end = message[param_start..-1].index(",") + param_start
  elsif message[param_start..-1].include? "\n"
    param_end = message[param_start..-1].index("\n") + param_start
  end

  res = message[param_start..param_end]
  res = res.gsub(param << ":", "")
  res = res.gsub(param << ": ", "")

  if res.include? "\n"
    res.gsub! "\n", ""
  end
  if res.include? ","
    res.gsub! ",", ""
  end
  res.strip
end