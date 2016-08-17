class CreatePathPortfolios < ActiveRecord::Migration
  def change
    create_table :path_portfolios do |t|
      t.integer :year
      t.timestamps null: false
    end
    
  end
end
