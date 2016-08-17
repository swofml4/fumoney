class PathAsset < ActiveRecord::Base
	belongs_to :path_portfolio
	belongs_to :asset_type
end
