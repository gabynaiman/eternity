require 'minitest_helper'

describe 'Sample usage' do

  def event(session, legend)
    text = "#{session.name} -> #{legend}"
    Eternity.logger.debug text
    Eternity.logger.debug ('-' * text.size)
    yield session if block_given?
    Eternity.logger.debug "Head: #{session.head.to_h}"
    Eternity.logger.debug "Delta: #{session.delta.to_h}"
    session.index.sections.each do |section|
      Eternity.logger.debug "Index #{section}: #{session[section].entries}"
    end
    Eternity.logger.debug
  end

  def print_keys
    Eternity.logger.debug Eternity.redis.call('KEYS', '*').sort.join("\n")
  end

  it 'test' do
    session = Eternity::Session.new :gaby

    event session, 'Initial status'

    event session, 'Add AR, BR, UY' do |s|
      s[:countries].add 'AR', name: 'Argentina'
      s[:countries].add 'BR', name: 'Brasil'
      s[:countries].add 'UY', name: 'Uruguay'
    end

    event session, 'Commit 1' do |s|
      s.commit author: 'Gabriel Naiman', message: 'Commit 1'
    end

    event session, 'Update BR' do |s|
      s[:countries].update 'BR', name: 'BRASIL'
    end

    event session, 'Commit 2' do |s|
      s.commit author: 'Gabriel Naiman', message: 'Commit 2'
    end

    event session, 'Remove UY' do |s|
      s[:countries].remove 'UY'
    end

    event session, 'Commit 3' do |s|
      s.commit author: 'Gabriel Naiman', message: 'Commit 3'
    end

    event session, 'Add CL and remove AR' do |s|
      s[:countries].add 'CL', name: 'Chile'
      s[:countries].remove 'AR'
    end

    event session, 'Revert all' do |s|
      s.revert
    end

    event session, 'Update AR and BR' do |s|
      s[:countries].update 'AR', name: 'Arg'
      s[:countries].update 'BR', name: 'Brasil'
    end

    event session, 'Revert AR' do |s|
      s[:countries].revert 'AR'
    end

    other_session = Eternity::Session.new :other
    event other_session, 'Checkout commit 1' do |s|
      s.checkout session.head.parents[0].parent_ids[0]
    end

    print_keys
  end

end