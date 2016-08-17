class CreateSimulations < ActiveRecord::Migration
  def change
    create_table :simulations do |t|
      t.string :title
      t.integer :number_of_paths
      t.integer :starting_age
      t.integer :retirement_age
      t.integer :last_simulation_age
      t.decimal :annual_contribution
      t.decimal :contribution_growth
      t.decimal :retirement_draw
      t.decimal :retirement_draw_growth
      t.decimal :risk_of_ruin
      t.string :simulation_status
      t.timestamps null: false
    end

  end
end
