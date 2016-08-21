class CreateCorrelations < ActiveRecord::Migration
  def change
    create_table :correlations do |t|
      t.decimal :correlation_amount, :precision => 6, :scale => 2
      t.timestamps null: false
    end
    
  end
end
