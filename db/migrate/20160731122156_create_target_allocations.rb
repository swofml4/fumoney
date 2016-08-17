class CreateTargetAllocations < ActiveRecord::Migration
  def change
    create_table :target_allocations do |t|
	  
      t.decimal :allocation
      t.timestamps null: false
    end
    
  end
end
