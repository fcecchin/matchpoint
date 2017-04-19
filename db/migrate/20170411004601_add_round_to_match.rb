class AddRoundToMatch < ActiveRecord::Migration[5.0]
  def change
    add_column :matches, :round, :integer
  end
end
