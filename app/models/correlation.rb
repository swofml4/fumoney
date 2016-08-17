class Correlation < ActiveRecord::Base
  belongs_to :correlation_collection
  belongs_to :asset_type1, :class_name => "AssetType"
  belongs_to :asset_type2, :class_name => "AssetType"
end
