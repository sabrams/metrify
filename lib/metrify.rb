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
      cattr_accessor :start_date
      cattr_accessor :end_date
    end
    base.send :extend, ClassMethods
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
  end

  module InstanceMethods
      
    def metrify_data
      self.class.metrify_data
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
      config_val(stat_name, 'display_name')
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
          raise MetrifyInclusionError, "Base class must implement method: #{new_meth}." if !self.class.respond_to?(new_meth) 
          return self.class.send(new_meth, *args, &block)
        elsif (name == method.to_s)
          return stat_hash[method.to_s]
        end
      end
      super
    end
    
    def preferred_stat_order
      metrify_data['stat_order']
    end
    
    def sort_stat_names(stat_names)
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
    def historical_values(end_date, history_length, unit = DEFAULT_UNIT)
      unit = :day if (1.send(unit) / 1.days) < 1
      days = 1.send(unit) / 1.days
      (0..(history_length-1)).map{|i| end_date - i.send(unit)}.reverse.map do |day|
        find_stats_for(day, days)
      end
    end
    
    def find_stats_for(end_date, days)
       s = lookup(end_date, days)
       s ||= generate(end_date, days)
    end
    
    def lookup(end_date = Time.now.midnight, interval = 1)
      self.class.find(:first, :conditions => {:finish_date => end_date, :number_of_days => interval})
    end
    
    def generate(end_date = Time.now.midnight, number_of_days = 1)
      s = self.class.find_or_create_by_finish_date_and_number_of_days(:finish_date => end_date, :number_of_days => number_of_days)
      self.start_date = end_date - number_of_days.days
      self.end_date = end_date
      s.stat_hash = {}
      stat_names.each do |stat_name|
#        raise MetrifyInclusionError, "Base class must implement method: #{stat_name}." unless self.class.respond_to?(stat_name)
        s.stat_hash[stat_name] = self.send(CALC + stat_name, end_date-number_of_days.days, end_date) 
      end

      s.finish_date = end_date
      s.save
      s
    end
  end
end