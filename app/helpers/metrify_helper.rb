module MetrifyHelper
  
  def pretty_col_name(name, metrify)
    configured_name = metrify.send(name + "_name")
    return configured_name if configured_name
    s = ""
    name = name.split('_')
    name.each {|word| s << ' '<< word.capitalize}
    s
  end

  def get_stat_arr(stat, historical_stats = @historical_site_stats)
    stat_over_time = []
    historical_stats.each do |s|
      value = s.send(stat)
      value = 0 if !value
      stat_over_time << value
    end
    stat_over_time
  end
  
  def sorted_stat_names
    #sort alphabetically, begin with finish_date
    @stat_names.sort.sort { |a,b| (a == "finish_date" ? 0 : 1) <=> (b == "finish_date" ? 0 : 1)}
  end
  
  def print_stat_value(stat, stat_name,  metrify, previous_stat = nil)
    val = stat.send(stat_name)
    val = number_with_precision(val, :precision => metrify.value_precision(stat_name)) if (metrify.value_precision(stat_name))
    if metrify.value_type(stat_name) == "currency"
      str = number_to_currency(val) 
    else
      str = val.to_s
    end   
    str += colorized_percent_diff(previous_stat.send(stat_name).to_f, stat.send(stat_name).to_f) if metrify.show_variance(stat_name) && previous_stat && previous_stat.send(stat_name) != 0 && stat.send(stat_name) != 0 && previous_stat.send(stat_name) != stat.send(stat_name)
    str
  end
  
  def colorized_percent_diff(prev, cur)
    val = percent_diff(prev, cur)
    str = "<span class="
    str += val >= 0 ? "stat_increase" : "stat_decrease"
    str += "> (" + number_to_percentage(val, :precision => 2)  + ")</span>"
  end
  
  def percent_diff(prev, cur)
    (cur-prev)*100/prev
  end
  
end
