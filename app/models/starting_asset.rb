class StartingAsset < ActiveRecord::Base
	belongs_to :simulation
	belongs_to :asset_type
end
