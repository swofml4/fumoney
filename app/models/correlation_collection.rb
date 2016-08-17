class CorrelationCollection < ActiveRecord::Base
	has_many :correlations
	accepts_nested_attributes_for :correlations, :allow_destroy => true, 
		:reject_if => proc { |attributes| attributes['_destroy'] == '1' }
end
