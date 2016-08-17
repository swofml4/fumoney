class CreateCorrelations < ActiveRecord::Migration
  def change
    create_table :correlations do |t|
      t.decimal :corr, :precision => 15, :scale => 10
      t.timestamps null: false
    end
    
  end
end
