class Account < ActiveRecord::Base

  has_many :expenses
  has_many :movements_out, :class_name => "Movement", :foreign_key => "from_account_id"
  has_many :movements_in, :class_name  => "Movement", :foreign_key => "to_account_id"
  
end
