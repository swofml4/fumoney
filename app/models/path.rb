class Path < ActiveRecord::Base
	belongs_to :simulation
	has_many :path_portfolios, :dependent => :destroy
end
