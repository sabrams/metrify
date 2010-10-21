module MetrifyHelper
  
  def pretty_col_name(name)
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
end
