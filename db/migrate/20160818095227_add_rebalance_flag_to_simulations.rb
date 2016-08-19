class AddRebalanceFlagToSimulations < ActiveRecord::Migration
  def change
    add_column :simulations, :rebalance_flag, :boolean
  end
end
