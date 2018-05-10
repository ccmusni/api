class Employee < ActiveRecord::Base
  self.table_name = 'tblEmployees'
  self.primary_key = 'Id'
end
