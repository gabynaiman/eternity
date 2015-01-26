require 'minitest_helper'

describe Model do

  let(:repository) { Repository.new :test }

  it 'Insert' do
    Repository.with :test do
      language = Language.create! name: 'Spanish'

      repository.changes_count.must_equal 1
      repository[:languages].to_h.must_equal language.id.to_s => [
        {
          'action' => 'insert', 
          'blob' => digest(language.attributes)
        }
      ]
    end
  end

  it 'Insert -> Update' do
    Repository.with :test do
      language = Language.create! name: 'Spanish'
      attrs_1 = language.attributes
      
      language.update_attributes name: 'English'
      attrs_2 = language.attributes

      repository.changes_count.must_equal 1
      repository[:languages].to_h.must_equal language.id.to_s => [
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
    Repository.with :test do
      language = Language.create! name: 'Spanish'
      attrs_1 = language.attributes
      
      language.destroy

      repository.changes_count.must_equal 1
      repository[:languages].to_h.must_equal language.id.to_s => [
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

  it 'Without current repository' do
    error = proc { Language.create! name: 'Spanish' }.must_raise RuntimeError
    error.message.must_equal 'Undefined current repository'
  end

end