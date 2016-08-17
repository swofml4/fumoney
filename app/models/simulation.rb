class Simulation < ActiveRecord::Base
	belongs_to :correlation_collection
	has_many :starting_assets, :dependent => :destroy
	has_many :target_allocations, :dependent => :destroy
	has_many :paths, :dependent => :destroy
	accepts_nested_attributes_for :starting_assets, :allow_destroy => true, 
		:reject_if => proc { |attributes| attributes['_destroy'] == '1' }
end
