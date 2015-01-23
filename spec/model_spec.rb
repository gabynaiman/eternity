require 'minitest_helper'

describe Model do

  let(:session) { Session.new :test }

  it 'Insert' do
    Session.with :test do
      language = Language.create! name: 'Spanish'

      session.changes_count.must_equal 1
      session[:languages].to_h.must_equal language.id.to_s => [
        {
          'action' => 'insert', 
          'blob' => digest(language.attributes)
        }
      ]
    end
  end

  it 'Insert -> Update' do
    Session.with :test do
      language = Language.create! name: 'Spanish'
      attrs_1 = language.attributes
      
      language.update_attributes name: 'English'
      attrs_2 = language.attributes

      session.changes_count.must_equal 1
      session[:languages].to_h.must_equal language.id.to_s => [
        {
          'action' => 'insert', 
          'blob' => digest(attrs_1)
        },
        {
          'action' => 'update', 
          'blob' => digest(attrs_2)
        }
      ]
    end
  end

  it 'Insert -> Delete' do
    Session.with :test do
      language = Language.create! name: 'Spanish'
      attrs_1 = language.attributes
      
      language.destroy

      session.changes_count.must_equal 1
      session[:languages].to_h.must_equal language.id.to_s => [
        {
          'action' => 'insert', 
          'blob' => digest(attrs_1)
        },
        {
          'action' => 'delete'
        }
      ]
    end
  end

  it 'Without current session' do
    error = proc { Language.create! name: 'Spanish' }.must_raise RuntimeError
    error.message.must_equal 'Undefined current session'
  end

end