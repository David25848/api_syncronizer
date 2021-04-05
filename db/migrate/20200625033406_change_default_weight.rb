class ChangeDefaultWeight < ActiveRecord::Migration[6.0]
  def change
    change_column :products, :weight, :string, default: "0.3"
    #Ex:- :default =>''
    #Ex:- change_column("admin_users", "email", :string, :limit =>25)
  end
end
