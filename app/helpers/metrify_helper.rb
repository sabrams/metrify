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
  
  def print_stat_value(stat, s, previous_stat = nil)
    str = stat.send(s).to_s
    str += colorized_percent_diff(previous_stat.send(s).to_f, stat.send(s).to_f) if @show_variance && previous_stat && previous_stat.send(s) != 0 && stat.send(s) != 0 && previous_stat.send(s) != stat.send(s)
    str
  end
  
  def colorized_percent_diff(prev, cur)
    val = percent_diff(prev, cur)
    str = "<span class="
    str += val >= 0 ? "stat_increase" : "stat_decrease"
    str += "> (" + number_to_percentage(val, :precision => 2)  + ")</p>"
  end
  
  def percent_diff(prev, cur)
    (cur-prev)*100/prev
  end
  
end
