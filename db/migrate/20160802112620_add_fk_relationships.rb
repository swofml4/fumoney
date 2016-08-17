class AddFkRelationships < ActiveRecord::Migration
  def change
  	add_reference :simulations, :correlation_collection, index: true, foreign_key: true
  	add_reference :starting_assets, :simulation, index: true, foreign_key: true
    add_reference :starting_assets, :asset_type, index: true, foreign_key: true
    add_reference :target_allocations, :simulation, index: true, foreign_key: true
    add_reference :target_allocations, :asset_type, index: true, foreign_key: true
    add_reference :path_assets, :asset_type, index: true, foreign_key: true
    add_reference :correlations, :correlation_collection, index: true, foreign_key: true
    add_column :correlations, :asset_type1_id, :integer
    add_foreign_key :correlations, :asset_types, column: :asset_type1_id
    add_column :correlations, :asset_type2_id, :integer
    add_foreign_key :correlations, :asset_types, column: :asset_type2_id
    add_reference :paths, :simulation, index: true, foreign_key: true
    add_reference :path_assets, :path_portfolio, index: true, foreign_key: true
    add_reference :path_portfolios, :path, index: true, foreign_key: true
  end
end
