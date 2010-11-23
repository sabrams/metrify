require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'

#DATE_1 = Date::strptime('20/10/2010', '%d/%m/%Y')
#DATE_2 = Date::strptime('21/10/2010', '%d/%m/%Y')
#DATE_3 = Date::strptime('22/10/2010', '%d/%m/%Y')

DATE_1 = Time.utc(2010,"oct",20,0,0,0)
DATE_2 = Time.utc(2010,"oct",21,0,0,0)
DATE_3 = Time.utc(2010,"oct",22,0,0,0)

RANGE_1 = 100
RANGE_2 = 10

#Abstract, really
class InvalidMetric < ActiveRecord::Base
  include Metrify
  acts_as_metrify 'spec/metrify.yml', true

  class << self
    def element_a_count(start_date, end_time)
      return 204 if (start_date == (DATE_1-1.day) && end_time == DATE_1)
      return 23 if (start_date == (DATE_1-7.days) && end_time == DATE_1)
      5 
    end

    def element_c_count(start_date, end_time)
      15
    end
    
    def element_1_count(start_date, end_time)
      15
    end
    
    def element_2_count(start_date, end_time)
      15
    end
    
    def element_3_count(start_date, end_time)
      15
    end
    
    def element_4_count(start_date, end_time)
      15
    end
    
    def element_cat_count(start_date, end_time)
      15
    end
    
    def element_dog_count(start_date, end_time)
      15
    end
  end
end

class Metric < InvalidMetric
  class << self
    def element_b_count(start_date, end_time)
      5
    end
  end
end

describe "Metrify" do
    
  it "should present a stat display name as a method of format $STAT_name" do
    Metric.element_a_count_name.should eql "Element A Count"
  end
  
  # it "should raise MetrifyInclusionError when stat method not implemented" do
  #     Metric = InvalidMetric.new
  #     lambda{Metric.historical_values(DATE_1, 1, :day)}.should raise_error(Metrify::MetrifyInclusionError)
  #   end

  it "should present a stat default display name when not specified in config" do
    Metric.element_c_count_name.should eql "Element C Count"
  end
  
  it "should return historical stats, per date range requested, with correct number of days" do
    @historical_site_stats = Metric.historical_values(DATE_1, RANGE_1, :day)
    @historical_site_stats.size.should eql 100
    (0..RANGE_1-1).each do |idx|
      @historical_site_stats[idx].number_of_hours.should eql 24
      @historical_site_stats[idx].finish_time.should eql DATE_1-(RANGE_1-1-idx).days
    end
  
    @historical_site_stats = Metric.historical_values(DATE_1, RANGE_2, :month)
    (0..RANGE_2-1).each do |idx|
      @historical_site_stats[idx].number_of_hours.should eql 30*24
      @historical_site_stats[idx].finish_time.should eql DATE_1-(RANGE_2-1-idx).months
    end    
  end
  
  it "should send start and correctly calculated end dates correctly to biz stat methods" do
    historical_site_stats = Metric.historical_values(DATE_1, 1, :day)
    
    historical_site_stats[0].element_a_count.should eql 204
    historical_site_stats = Metric.historical_values(DATE_1, 2, :day)
    historical_site_stats[0].element_a_count.should eql 5
    historical_site_stats = Metric.historical_values(DATE_1, 1, :week)
    historical_site_stats[0].element_a_count.should eql 23  
  end
  
  it "should return filters with hash of hashes" do
    Metric.filters['type'].keys.to_set.should eql ['numbers', 'letters', 'animals'].to_set
    Metric.filters['type']['numbers']['set'].to_set.should eql ['element_1_count', 'element_2_count', 'element_3_count', 'element_4_count'].to_set
    Metric.filters['furriness'].keys.to_set.should eql ['furry', 'not_furry'].to_set
  end
  
  it "should return all stat names with no filters" do
    Metric.stat_names.to_set.should eql Set.new ['element_a_count', 'element_b_count', 'element_c_count', 'element_1_count', 'element_2_count', 'element_3_count', 'element_4_count', 'element_cat_count', 'element_dog_count']
  end
  
  it "should honor filters when returning stat names" do
    filters = {'type' => ['numbers', 'letters'], 'furriness' => ['furry', 'not_furry']}
    Metric.stat_names(nil, filters).to_set.should eql Set.new ['element_a_count', 'element_b_count', 'element_c_count', 'element_1_count', 'element_2_count', 'element_3_count', 'element_4_count']
  end
  
end
