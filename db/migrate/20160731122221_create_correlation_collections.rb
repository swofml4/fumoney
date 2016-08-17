class CreateCorrelationCollections < ActiveRecord::Migration
  def change
    create_table :correlation_collections do |t|
      t.string :title
      t.timestamps null: false
    end
  end
end
