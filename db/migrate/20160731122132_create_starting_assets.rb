class CreateStartingAssets < ActiveRecord::Migration
  def change
    create_table :starting_assets do |t|
      
      t.decimal :amount
      t.timestamps null: false
    end
    
  end
end
