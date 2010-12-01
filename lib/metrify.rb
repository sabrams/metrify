require 'yaml'

module Metrify

  
  DEFAULT_UNIT = :day 
  CALC = "calc_"
  NAME = '_name'
  
  class MetrifyInclusionError < StandardError; end
  class MetrifyMethodMissingError < StandardError; end
  
  def self.included(base)
    raise MetrifyInclusionError, "The base class must be a descendent of active record." unless base.respond_to?(:descends_from_active_record?)
    base.class_eval do
      cattr_accessor :metrify_data
    end
    base.send :extend, ClassMethods
  end

  module InstanceMethods
    def method_missing(method, *args, &block)
      self.class.stat_names.each do |name|
        return stat_hash[name] if (name == method.to_s)
      end
      super
    end
  end
      
  module ClassMethods
    
    def acts_as_metrify(file = self.name.underscore + '_metrify.yml', test = false)
      serialize :stat_hash, Hash
      send :include, InstanceMethods
      if test
        self.metrify_data = YAML::load_file(file) 
      else
        self.metrify_data = YAML.load_file(File.join(RAILS_ROOT, 'config', file))
      end
    end
    
    def filters
      metrify_data['filters']
    end
    
    # currency
    def value_type(stat_name)
      config_val(stat_name, 'value_type')
    end
    
    # int
    def value_precision(stat_name)
      config_val(stat_name, 'precision')
    end
    
    # if stat should also have % +/- over previous time period
    def show_variance(stat_name)
      config_val(stat_name, 'show_variance')
    end    
    
    def display_name(stat_name)
      configured_name = config_val(stat_name, 'display_name')
      return configured_name if configured_name
      s = ""
      name = stat_name.split('_')
      name.each {|word| s << ' '<< word.capitalize}
      s
    end
    
    def config_val(stat_name, val)
      metrify_data['stats'][stat_name] == nil ? nil : metrify_data['stats'][stat_name][val]
    end
    
    def method_missing(method, *args, &block)
      stat_names.each do |name|
        if (name + NAME == method.to_s)
          return display_name(name)
        elsif (CALC + name == method.to_s)
          new_meth = method.to_s[CALC.length,method.to_s.length]
          raise MetrifyInclusionError, "Base class must implement method: #{new_meth}." if !self.respond_to?(new_meth) 
          return self.send(new_meth, *args, &block)
        end
      end
      super
    end
    
    def preferred_stat_order
      metrify_data['stat_order']
    end
    
    def sorted_stat_names(stat_names = stat_names)
      if preferred_stat_order
        final_list = []
        preferred_stat_order.each do |o_stat|
          final_list << o_stat if stat_names.include?(o_stat)
        end
        final_list
      else
        #sort alphabetically
        stat_names.sort
      end
    end
    
    def stat_names(names = nil, my_filters = nil)
      #filters = ['type' => ['numbers', 'letters'], 'furriness' => ['furry', 'not_furry']]
      if my_filters
        col_names = names || metrify_data['stats'].keys
        final_col_names = col_names.clone
        my_filters.each do |filter_type, filter_subtypes|
          filter_col_names = []
          filters.keys.each do |filter_type_from_config|
            if (filter_type_from_config == filter_type)
              filter_subtypes.each do |subtype|
                filters[filter_type_from_config][subtype]['set'].each do |col|
                  filter_col_names << col
                end
              end
            end
          end
          col_names.each do |ycol|
              final_col_names.delete(ycol.to_s) if !filter_col_names.include?(ycol) 
          end
        end
        final_col_names
      else
        names || metrify_data['stats'].keys
      end
      
    end

    # returns an array of defined stats, each containing an array of values over time
    def historical_values(end_time, history_length, unit = DEFAULT_UNIT)
      unit = :hour if (1.send(unit) / 1.hours) < 1
      finish_time = unit == :hour ? floor_hour(end_time) : end_time.midnight
      hours = 1.send(unit) / 1.hours
      (0..(history_length-1)).map{|i| finish_time - i.send(unit)}.reverse.map do |hour|
        find_stats_for(hour, hours)
      end
    end
    
    def find_stats_for(end_time, hours)
      end_time = floor_hour(end_time)
      s = lookup(end_time, hours)
      s ||= generate(end_time, hours)
    end
    
    private
    
    def lookup(end_time = floor_hour(Time.zone.now), interval = 1)
      find(:first, :conditions => {:finish_time => end_time, :number_of_hours => interval})
    end
    
    def generate(end_time = floor_hour(Time.zone.now), number_of_hours = 1)
      s = find_or_create_by_finish_time_and_number_of_hours(:finish_time => end_time, :number_of_hours => number_of_hours)
      start_time = end_time - number_of_hours.hours
      s.stat_hash = {}
      stat_names.each do |stat_name|
#        raise MetrifyInclusionError, "Base class must implement method: #{stat_name}." unless self.class.respond_to?(stat_name)
        s.stat_hash[stat_name] = self.send(CALC + stat_name, end_time-number_of_hours.hours, end_time) 
      end

      s.finish_time = end_time
      s.save
      s
    end
    
    # Instead of extending Time...
    #class Time
    # def floor_hour
    # Time.at((self.to_f / 3600).floor * 3600)
    # end
    #end
    # using private method....
    def floor_hour(time)
      (Time.zone || Time).at((time.to_f/3600).floor * 3600)
    end
      
    
  end

  module InstanceMethods
      
    
  end
end