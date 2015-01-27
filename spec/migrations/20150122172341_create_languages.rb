class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.uuid :id, primary_key: true
      t.string :name, null: false
      t.timestamps
    end
  end
end