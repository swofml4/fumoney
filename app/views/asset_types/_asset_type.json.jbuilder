json.extract! asset_type, :id, :name, :historical_std_deviation, :historical_average_return, :created_at, :updated_at
json.url asset_type_url(asset_type, format: :json)