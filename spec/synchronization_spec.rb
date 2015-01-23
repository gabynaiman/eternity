require 'minitest_helper'

describe 'Synchronization' do

  let(:other_session) { Session.new :session_2 }
  
  it 'Commit -> Pull' do
    skip

    other_session.tap do |s|
      s[:languages].insert '1', name: 'Spanish', created_at: Time.now, updated_at: Time.now
      s.commit author: 'Session 2', message: 'Lang: Spanish'
      s.push
    end

    Session.with :session_1 do |s|
      Synchronizer.pull
    end
  end

end


# class Synchronizer

#   def self.pull
#     actual_commit = Session.current.current_commit
#     Session.current.pull
#     apply Session.current.current_commit.delta_from actual_commit
#   end

#   def self.apply(delta)
#     script = delta.map do

#     end
#     ActiveRecord::Base.connection.execute script
#   end

# end