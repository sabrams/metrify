require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

DATE_1 = Date::strptime('20/10/2010', '%d/%m/%Y')
DATE_2 = Date::strptime('21/10/2010', '%d/%m/%Y')
DATE_3 = Date::strptime('22/10/2010', '%d/%m/%Y')

RANGE_1 = 100
RANGE_2 = 10

#Abstract, really
class InvalidMetric < ActiveRecord::Base
  include Metrify
  acts_as_site_stat 'spec/metrify.yml', true

  class << self
    def element_a_count(start_date, end_date)
      return 204 if (start_date == (DATE_1-1) && end_date == DATE_1)
      return 23 if (start_date == (DATE_1-7) && end_date == DATE_1)
      5 
    end

    def element_c_count(start_date, end_date)
      15
    end
  end
end

class Metric < InvalidMetric
  class << self
    def element_b_count(start_date, end_date)
      5
    end
  end
end

describe "Metrify" do
  
  before(:each) do
        
    @site_stat = Metric.new
  end  
    
  it "should present a stat display name as a method of format $STAT_name" do
    @site_stat.element_a_count_name.should eql "Element A Count"
  end
  
  # it "should raise MetrifyInclusionError when stat method not implemented" do
  #     @site_stat = InvalidMetric.new
  #     lambda{@site_stat.historical_values(DATE_1, 1, :day)}.should raise_error(Metrify::MetrifyInclusionError)
  #   end

#   TODO?
  it "should present a stat default display name when not specified in config" do
    @site_stat.element_c_count_name.should eql "Element C Count"
  end
  
  it "should return historical stats, per date range requested, with correct number of days" do
    @historical_site_stats = @site_stat.historical_values(DATE_1, RANGE_1, :day)
    @historical_site_stats.size.should eql 100
    (0..RANGE_1-1).each do |idx|
      @historical_site_stats[idx].finish_date.should eql DATE_1-(RANGE_1-1-idx)
      @historical_site_stats[idx].number_of_days.should eql 1
    end
  
    @historical_site_stats = @site_stat.historical_values(DATE_1, RANGE_2, :month)
    (0..RANGE_2-1).each do |idx|
      @historical_site_stats[idx].finish_date.should eql DATE_1-(RANGE_2-1-idx).months
      @historical_site_stats[idx].number_of_days.should eql 30
    end    
  end
  
  it "should send start and correctly calculated end dates correctly to biz stat methods" do
    historical_site_stats = @site_stat.historical_values(DATE_1, 1, :day)
    
    historical_site_stats[0].element_a_count.should eql 204
    historical_site_stats = @site_stat.historical_values(DATE_1, 2, :day)
    historical_site_stats[0].element_a_count.should eql 5
    historical_site_stats = @site_stat.historical_values(DATE_1, 1, :week)
    historical_site_stats[0].element_a_count.should eql 23  
  end
  
  it "should return top-level filters" do
    @site_stat.filters.keys.should eql ['platforms', 'activities']
  end
  
  it "should return set of next-tier filters and description" do
    @site_stat.filters['platforms']['set'].should eql ['iphone', 'blackberry', 'android', 'website']
    @site_stat.filters['platforms']['description'].should eql 'Platforms'
  end
  
  
  it "should return an object with stats for a designated date and range" do
    
    #@site_stat.find_stats_for(DATE_1, RANGE_1)
    #@site_stat.
    # def find_stats_for(end_date, days)
    #    s = lookup(end_date, days)
    #    s ||= generate(end_date, days)
    # end
  end
  
  # it "should return the evaluation of the class method for a stat value method" do
  #     @site_stat.element_a_count.should eql 293
  #   end
  
end
