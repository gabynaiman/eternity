class Country < ActiveRecord::Base
  include Eternity::Model
  belongs_to :language
end