require 'minitest_helper'

describe Commit do

  let(:session) { Session.new :test }

  it 'First commit' do
    session[:countries].add 'AR', name: 'Argentina'

    commit_id = session.commit author: 'User', message: 'Commit message'

    session.delta.must_be_empty
    session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    session.head_id.must_equal commit_id
    session.head.author.must_equal 'User'
    session.head.message.must_equal 'Commit message'
    session.head.parent_ids.must_equal []
  end

end