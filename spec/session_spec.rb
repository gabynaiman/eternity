require 'minitest_helper'

describe Session do

  let(:session) { Session.new :test }

  it 'Initial status' do
    session.wont_be :changes?
    session.wont_be :current_commit?
    session.current_branch.must_equal 'master'
    session.branches.must_be_empty
  end

  it 'Commit' do
    session[:countries].insert 'AR', name: 'Argentina'

    session.changes.must_equal 'countries' => {'AR' => {'event' => 'insert', 'data' => {'name' => 'Argentina'}}}

    commit = session.commit author: 'User', message: 'Commit message'

    session.changes.must_be_empty

    session.current_commit.tap do |current_commit|
      current_commit.id.must_equal commit.id
      current_commit.time.must_be_instance_of Time
      current_commit.author.must_equal 'User'
      current_commit.message.must_equal 'Commit message'
      current_commit.parents.must_equal []
      # current_commit.delta.must_equal 'countries' => {'added' => ['AR']}
      # current_commit.must_equal_index 'countries' => {'AR' => {'name' => 'Argentina'}}
    end
  end
  
end