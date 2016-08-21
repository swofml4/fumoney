class CreateSimulations < ActiveRecord::Migration
  def change
    create_table :simulations do |t|
      t.string :title
      t.integer :number_of_paths
      t.integer :starting_age
      t.integer :retirement_age
      t.integer :last_simulation_age
      t.decimal :annual_contribution, :precision => 12, :scale => 2
      t.decimal :contribution_growth, :precision => 6, :scale => 2
      t.decimal :retirement_draw, :precision => 12, :scale => 2
      t.decimal :retirement_draw_growth, :precision => 6, :scale => 2
      t.decimal :risk_of_ruin, :precision => 6, :scale => 2
      t.string :simulation_status
      t.timestamps null: false
    end

  end
end
