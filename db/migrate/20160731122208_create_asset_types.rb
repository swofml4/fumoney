class CreateAssetTypes < ActiveRecord::Migration
  def change
    create_table :asset_types do |t|
      t.string :name
      t.decimal :historical_std_deviation, :precision => 6, :scale => 2
      t.decimal :historical_average_return, :precision => 6, :scale => 2
      t.timestamps null: false
    end
  end
end
