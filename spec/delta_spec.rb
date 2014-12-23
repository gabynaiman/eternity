require 'minitest_helper'

describe 'Delta' do

  describe 'Merge' do
  
    it 'Add -> Add' do
      delta_1 = {'countries' => {'added' => ['AR']}}
      delta_2 = {'countries' => {'added' => ['UY']}}

      Delta.merge(delta_1, delta_2).must_equal 'countries' => {'added' => ['AR', 'UY']}
    end

    it 'Add -> Update' do
      delta_1 = {'countries' => {'added' => ['AR']}}
      delta_2 = {'countries' => {'updated' => ['AR']}}

      Delta.merge(delta_1, delta_2).must_equal 'countries' => {'added' => ['AR']}
    end

    it 'Add -> Remove' do
      delta_1 = {'countries' => {'added' => ['AR']}}
      delta_2 = {'countries' => {'removed' => ['AR']}}

      Delta.merge(delta_1, delta_2).must_be_empty
    end

    it 'Update -> Update' do
      delta_1 = {'countries' => {'updated' => ['AR']}}
      delta_2 = {'countries' => {'updated' => ['AR']}}

      Delta.merge(delta_1, delta_2).must_equal 'countries' => {'updated' => ['AR']}
    end

    it 'Update -> Remove' do
      delta_1 = {'countries' => {'updated' => ['AR']}}
      delta_2 = {'countries' => {'removed' => ['AR']}}

      Delta.merge(delta_1, delta_2).must_equal 'countries' => {'removed' => ['AR']}
    end

    it 'Remove -> Add' do
      delta_1 = {'countries' => {'removed' => ['AR']}}
      delta_2 = {'countries' => {'added' => ['AR']}}

      Delta.merge(delta_1, delta_2).must_equal 'countries' => {'updated' => ['AR']}
    end

    it 'Add -> Update -> Remove' do
      delta_1 = {'countries' => {'added' => ['AR']}}
      delta_2 = {'countries' => {'updated' => ['AR']}}
      delta_3 = {'countries' => {'removed' => ['AR']}}

      Delta.merge(delta_1, delta_2, delta_3).must_be_empty
    end

    it 'Add -> Remove -> Add' do
      delta_1 = {'countries' => {'added' => ['AR']}}
      delta_2 = {'countries' => {'removed' => ['AR']}}
      delta_3 = {'countries' => {'added' => ['AR']}}

      Delta.merge(delta_1, delta_2, delta_3).must_equal 'countries' => {'added' => ['AR']}
    end

  end

end