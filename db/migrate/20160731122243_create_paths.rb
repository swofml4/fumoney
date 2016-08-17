class CreatePaths < ActiveRecord::Migration
  def change
    create_table :paths do |t|
      t.string :path_type
      t.string :path_title
      t.timestamps null: false
    end
    
  end
end
