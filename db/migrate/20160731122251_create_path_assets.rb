class CreatePathAssets < ActiveRecord::Migration
  def change
    create_table :path_assets do |t|
      t.decimal :starting_amount
      t.decimal :return_amount
      t.decimal :contributions_or_draw_amount
      t.decimal :rebalance_amount
      t.decimal :ending_amount
      t.timestamps null: false
    end
    
  end
end
