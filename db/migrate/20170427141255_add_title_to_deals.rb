class AddTitleToDeals < ActiveRecord::Migration[5.0]
  def change
    add_column :deals, :title, :string
  end
end
