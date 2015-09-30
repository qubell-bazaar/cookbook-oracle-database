actions :create

attribute :user, :kind_of => String, :name_attribute => true
attribute :password, :kind_of => String
attribute :grants, :kind_of => Array, :default => []

