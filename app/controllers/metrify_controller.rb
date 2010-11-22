module MetrifyController
  
  def self.included(base)
    base.class_eval do
      before_filter :set_metrify_class
    end
    base.extend ClassMethods
    base.send :include, InstanceMethods
    base.helper MetrifyHelper
  end
  
  module InstanceMethods
   def index
     setup_historical_stats
     @stat_names = @metrified_class.stat_names
     @historical_site_stats.reverse!
   end
   
   def set_metrify_class
     @metrified_class = metrify_model
   end

   def setup_historical_stats
     @unit = unit
     @number_of_stats = number_of_stats
     @historical_site_stats = @metrified_class.historical_values(Time.zone.now.beginning_of_week, number_of_stats, unit)
   end
   
   def number_of_stats

    number = case unit.to_sym
      when :month then 12
      when :week then 52
      when :day then 30
      else 48 #hour
    end
    
   end

   def unit
     params[:unit] || :week
   end

   def graph_stats
     prepare_for_graph

     @stat_names = parsed_stat_names
   end
   
   def parsed_stat_names
     !params[:stat_names].blank? ? params[:stat_names].split(',') : @metrified_class.stat_names
  end
   
   # chart_data.json?filters[type][]=letters&filters[type][]=animals&filters[furriness][]=not_furry
   def chart_data
    @stat_names = @metrified_class.stat_names(parsed_stat_names, params[:filters])
    @unit = params[:unit] || unit

    @number_of_stats = params[:number_of_stats] || number_of_stats
    @historical_site_stats = @metrified_class.historical_values(Time.zone.now.beginning_of_week, number_of_stats, unit)

    json = @stat_names.map{|s| {:name => @metrified_class.display_name(s), 
                                :pointInterval => (1.send(@unit) * 1000), 
                                :pointStart => (@number_of_stats.send(@unit).ago.to_i * 1000), 
                                :data => @historical_site_stats.map{|h| h.send(s)}}}

    setup_historical_stats
    respond_to do |format|
      format.json {
        render :layout => false , :json => @stat_names.map{|s| {:name => @metrified_class.display_name(s), 
          :pointInterval => (1.send(@unit) * 1000), 
          :pointStart => (@number_of_stats.send(@unit).ago.to_i * 1000), 
          :data => @template.get_stat_arr(s, @historical_site_stats)}}.to_json
          }
    end
    
   end
   
#   def set_metrify_model; end
   
   private
   
   def prepare_for_graph
     setup_historical_stats
   end
   
  end

 
  module ClassMethods

  end
end

