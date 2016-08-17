class AddCorrelationRateToCorrelations < ActiveRecord::Migration
  def change
    add_column :correlations, :correlation_amount, :decimal
  end
end
