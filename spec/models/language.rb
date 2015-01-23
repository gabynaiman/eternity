class Language < ActiveRecord::Base
  include Eternity::Model
  has_many :countries
end