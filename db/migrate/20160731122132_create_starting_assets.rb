class CreateStartingAssets < ActiveRecord::Migration
  def change
    create_table :starting_assets do |t|
      
      t.decimal :amount, :precision => 12, :scale => 2
      t.timestamps null: false
    end
    
  end
end
