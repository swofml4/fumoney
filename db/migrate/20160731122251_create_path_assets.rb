class CreatePathAssets < ActiveRecord::Migration
  def change
    create_table :path_assets do |t|
      t.decimal :starting_amount, :precision => 12, :scale => 2
      t.decimal :return_amount, :precision => 12, :scale => 2
      t.decimal :contributions_or_draw_amount, :precision => 12, :scale => 2
      t.decimal :rebalance_amount, :precision => 12, :scale => 2
      t.decimal :ending_amount, :precision => 12, :scale => 2
      t.decimal :return_rate, :precision => 6, :scale => 2
      t.timestamps null: false
    end
    
  end
end
