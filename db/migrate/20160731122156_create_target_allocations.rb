class CreateTargetAllocations < ActiveRecord::Migration
  def change
    create_table :target_allocations do |t|
	  
      t.decimal :allocation, :precision => 6, :scale => 2
      t.timestamps null: false
    end
    
  end
end
