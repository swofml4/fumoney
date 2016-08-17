class CreateAssetTypes < ActiveRecord::Migration
  def change
    create_table :asset_types do |t|
      t.string :name
      t.decimal :historical_std_deviation
      t.decimal :historical_average_return
      t.timestamps null: false
    end
  end
end
