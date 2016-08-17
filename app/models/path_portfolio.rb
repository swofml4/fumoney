class PathPortfolio < ActiveRecord::Base
	belongs_to :path
	has_many :path_assets, :dependent => :destroy
end
