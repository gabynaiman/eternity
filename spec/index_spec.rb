require 'minitest_helper'

describe 'Index' do
  
  let(:session) { Session.new :test }

  describe 'Before commit' do

    it 'Initial status' do
      session.changes.must_be_empty
      session.entries.must_be_empty
    end

    it 'Add' do
      session[:countries].add 'AR', name: 'Argentina'

      session.changes.must_equal 'countries' => {'added' => ['AR']}
      session.entries.must_equal 'countries' => {'AR' => digest(name: 'Argentina')}
    end

    it 'Add existent' do
      session[:countries].add 'AR', name: 'Argentina'

      error = proc { session[:countries].add 'AR', name: 'Argentina' }.must_raise RuntimeError
      error.message.must_equal 'Index add error. Countries AR already exists'
    end

    it 'Add -> Update' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'

      session.changes.must_equal 'countries' => {'added' => ['AR']}
      session.entries.must_equal 'countries' => {'AR' => digest(name: 'Argentina', code: 'ARG')}
    end

    it 'Add -> Remove' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'
      session[:countries].remove 'AR'

      session.changes.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
    end

    it 'Add -> Update -> Remove' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].remove 'AR'

      session.changes.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
    end

    it 'Update invalid' do
      error = proc { session[:countries].update 'INVALID', name: 'Invalid' }.must_raise RuntimeError
      error.message.must_equal 'Index update error. Countries INVALID not found'
    end

    it 'Remove invalid' do
      error = proc { session[:countries].remove 'INVALID' }.must_raise RuntimeError
      error.message.must_equal 'Index remove error. Countries INVALID not found'
    end

    it 'Revert' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'

      session[:countries].revert 'AR'

      session.changes.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
    end

    it 'Revert all' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:cities].add 'CABA', name: 'Ciudad Autonoma de Buenos Aires'

      session.revert

      session.changes.must_be_empty
      session.entries.must_be_empty
    end

    it 'Revert invalid' do
      error = proc { session[:countries].revert 'INVALID' }.must_raise RuntimeError
      error.message.must_equal 'Index revert error. Countries INVALID not found'
    end

  end

  describe 'After commit' do

    before do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'
      
      session.commit author: 'User', message: 'Commit message'

      session.changes.must_be_empty
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay')
      }
    end

    it 'Update' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'

      session.changes.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina', code: 'ARG'), 
        'UY' => digest(name: 'Uruguay')
      }
    end

    it 'Update twice' do
      2.times { session[:countries].update 'AR', name: 'Argentina', code: 'ARG' }

      session.changes.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina', code: 'ARG'), 
        'UY' => digest(name: 'Uruguay')
      }
    end

    it 'Update -> Remove' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].remove 'AR'

      session.changes.must_equal 'countries' => {'removed' => ['AR']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
    end

    it 'Remove' do 
      session[:countries].remove 'AR'

      session.changes.must_equal 'countries' => {'removed' => ['AR']}
      session.entries.must_equal 'countries' => {'UY' => digest(name: 'Uruguay')}
    end

    it 'Remove -> Add' do
      session[:countries].remove 'AR'
      session[:countries].add 'AR', name: 'Argentina'

      session.changes.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina'),
        'UY' => digest(name: 'Uruguay')
      }
    end

    it 'Revert updated' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'

      session.changes.must_equal 'countries' => {'updated' => ['AR', 'UY']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina', code: 'ARG'), 
        'UY' => digest(name: 'Uruguay', code: 'URU')
      }

      session[:countries].revert 'AR'

      session.changes.must_equal 'countries' => {'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina'),
        'UY' => digest(name: 'Uruguay', code: 'URU')
      }
    end

    it 'Revert removed' do
      session[:countries].remove 'AR'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'

      session.changes.must_equal 'countries' => {'removed' => ['AR'], 'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'UY' => digest(name: 'Uruguay', code: 'URU')
      }

      session[:countries].revert 'AR'

      session.changes.must_equal 'countries' => {'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina'),
        'UY' => digest(name: 'Uruguay', code: 'URU')
      }
    end

    it 'Revert all' do
      session[:countries].remove 'AR'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'
      session[:countries].add 'BR', name: 'Brasil'

      session.changes.must_equal 'countries' => {'removed' => ['AR'], 'updated' => ['UY'], 'added' => ['BR']}
      session.entries.must_equal 'countries' => {
        'UY' => digest(name: 'Uruguay', code: 'URU'),
        'BR' => digest(name: 'Brasil')
      }

      session.revert

      session.changes.must_be_empty
      session.entries.must_equal 'countries' => {
        'AR' => digest(name: 'Argentina'), 
        'UY' => digest(name: 'Uruguay')
      }
    end

  end

end