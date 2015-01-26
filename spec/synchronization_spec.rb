require 'minitest_helper'

describe 'Synchronization' do

  let(:other_repository) { Repository.new :repository_2 }
  
  it 'Commit -> Pull' do
    skip

    other_repository.tap do |s|
      s[:languages].insert '1', name: 'Spanish', created_at: Time.now, updated_at: Time.now
      s.commit author: 'Repository 2', message: 'Lang: Spanish'
      s.push
    end

    Repository.with :repository_1 do |s|
      Synchronizer.pull
    end
  end

end


# class Synchronizer

#   def self.pull
#     actual_commit = Repository.current.current_commit
#     Repository.current.pull
#     apply Repository.current.current_commit.delta_from actual_commit
#   end

#   def self.apply(delta)
#     script = delta.map do

#     end
#     ActiveRecord::Base.connection.execute script
#   end

# end