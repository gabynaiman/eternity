require 'minitest_helper'

describe 'Synchronization flow' do
  
  let(:session) { Session.new :test }

  it 'Initial status' do
    session.current_commit?.must_equal false
    session.current_commit.must_be_nil
    session.current_branch.must_equal 'master'
    session.branches.must_be_empty
  end

  it 'Create branch' do
    session[:countries].add 'AR', name: 'Argentina'
    commit_id = session.commit author: 'User', message: 'Commit message'

    session.current_commit?.must_equal true
    session.current_commit.id.must_equal commit_id
    session.current_branch.must_equal 'master'
    session.branches.must_equal 'master' => commit_id

    session.branch :test_branch

    session.branches.must_equal 'master' => commit_id, 
                                'test_branch' => commit_id

    # session.current_commit?.must_equal true
    # session.current_commit.id.must_equal commit_id
    # session.current_branch.must_equal 'test_branch'
    # session.branches.must_equal 'master' => commit_id, 'test_branch' => commit_id
  end

  # it 'Create branch without commit'
  
  # it 'Create branch with uncommitted changes'

  # it 'Checkout local branch'

  # it 'Checkout remote branch'

  # it 'Checkout invalid branch'

  # it 'Push new branch'

end


=begin

session_1 = Session.new :user_1

session_1.head.branch # => master

session_1.index[:countries].add 'AR', name: 'Argentina'
session_1.commit message: 'Commit 1', author: 'user'
session_1.push # master

session_1.branch :spanish
session_1.checkout :spanish

session_1.index[:countries].add 'BR', name: 'Brasil'
session_1.commit message: 'Commit 2', author: 'user'
session_1.push # spanish

# -----------------------------------

session_2 = Session.new :user_2

session_2.head.branch # => master

session_2.checkout :spanish
session_2.pull # spanish
# => session_2.merge 123456798
# => session_2.commit message: 'Merge spanish to spanish', author: 'system'

session_2.checkout :master
session_2.merge_branch :spanish # merge 123456798
# => session_2.commit message: 'Merge spanish to master', author: 'system'
session_2.push # master

=end
