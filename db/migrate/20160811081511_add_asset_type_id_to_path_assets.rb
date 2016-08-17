class AddAssetTypeIdToPathAssets < ActiveRecord::Migration
  def change
    add_column :path_assets, :asset_type_id, :integer
  end
end
