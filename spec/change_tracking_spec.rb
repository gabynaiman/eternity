require 'minitest_helper'

describe 'Change Tracking' do
  
  let(:session) { Session.new :test }

  describe 'Before commit' do

    it 'Initial status' do
      session.delta.must_be_empty
      session.entries.must_be_empty
    end

    it 'Add' do
      session[:countries].add 'AR', name: 'Argentina'

      session.delta.must_equal 'countries' => {'added' => ['AR']}
      session.entries.must_equal 'countries' => {'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8'}
    end

    it 'Add existent' do
      session[:countries].add 'AR', name: 'Argentina'

      error = proc { session[:countries].add 'AR', name: 'Argentina' }.must_raise RuntimeError
      error.message.must_equal 'Index add error. Countries AR already exists'
    end

    it 'Add -> Update' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'

      session.delta.must_equal 'countries' => {'added' => ['AR']}
      session.entries.must_equal 'countries' => {'AR' => '2fc541751e0a9488b6dedba1e9154396bdf657dd'}
    end

    it 'Add -> Remove' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'
      session[:countries].remove 'AR'

      session.delta.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
    end

    it 'Add -> Update -> Remove' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:countries].add 'UY', name: 'Uruguay'
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].remove 'AR'

      session.delta.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
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

      session.delta.must_equal 'countries' => {'added' => ['UY']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
    end

    it 'Revert all' do
      session[:countries].add 'AR', name: 'Argentina'
      session[:cities].add 'CABA', name: 'Ciudad Autonoma de Buenos Aires'

      session.revert

      session.delta.must_be_empty
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

      session.delta.must_be_empty
      session.entries.must_equal 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8', 
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
      }
    end

    it 'Update' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'

      session.delta.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => '2fc541751e0a9488b6dedba1e9154396bdf657dd', 
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
      }
    end

    it 'Update twice' do
      2.times { session[:countries].update 'AR', name: 'Argentina', code: 'ARG' }

      session.delta.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => '2fc541751e0a9488b6dedba1e9154396bdf657dd', 
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
      }
    end

    it 'Update -> Remove' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].remove 'AR'

      session.delta.must_equal 'countries' => {'removed' => ['AR']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
    end

    it 'Remove' do 
      session[:countries].remove 'AR'

      session.delta.must_equal 'countries' => {'removed' => ['AR']}
      session.entries.must_equal 'countries' => {'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'}
    end

    it 'Remove -> Add' do
      session[:countries].remove 'AR'
      session[:countries].add 'AR', name: 'Argentina'

      session.delta.must_equal 'countries' => {'updated' => ['AR']}
      session.entries.must_equal 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8',
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
      }
    end

    it 'Revert updated' do
      session[:countries].update 'AR', name: 'Argentina', code: 'ARG'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'

      session.delta.must_equal 'countries' => {'updated' => ['AR', 'UY']}
      session.entries.must_equal 'countries' => {
        'AR' => '2fc541751e0a9488b6dedba1e9154396bdf657dd', 
        'UY' => '79f1d7fbec500784dc646fbe2595a69d7776cee7'
      }

      session[:countries].revert 'AR'

      session.delta.must_equal 'countries' => {'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8',
        'UY' => '79f1d7fbec500784dc646fbe2595a69d7776cee7'
      }
    end

    it 'Revert removed' do
      session[:countries].remove 'AR'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'

      session.delta.must_equal 'countries' => {'removed' => ['AR'], 'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'UY' => '79f1d7fbec500784dc646fbe2595a69d7776cee7'
      }

      session[:countries].revert 'AR'

      session.delta.must_equal 'countries' => {'updated' => ['UY']}
      session.entries.must_equal 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8',
        'UY' => '79f1d7fbec500784dc646fbe2595a69d7776cee7'
      }
    end

    it 'Revert all' do
      session[:countries].remove 'AR'
      session[:countries].update 'UY', name: 'Uruguay', code: 'URU'
      session[:countries].add 'BR', name: 'Brasil'

      session.delta.must_equal 'countries' => {'removed' => ['AR'], 'updated' => ['UY'], 'added' => ['BR']}
      session.entries.must_equal 'countries' => {
        'UY' => '79f1d7fbec500784dc646fbe2595a69d7776cee7',
        'BR' => 'd9623f086a613d36cf0cc5692c2542750e099ba9'
      }

      session.revert

      session.delta.must_be_empty
      session.entries.must_equal 'countries' => {
        'AR' => '47516589a5d9b79cacb6f8be945d68bdccee22d8', 
        'UY' => '5fdac9a212c2af7184bae7a1225147471bf9f31f'
      }
    end

  end

end