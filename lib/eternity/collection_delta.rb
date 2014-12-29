module Eternity
  class CollectionDelta

    Changes = Restruct::NestedHash.new Restruct::Set

    def initialize(options)
      @changes = Changes.new options
    end

    def add(id)
      if removed? id
        removed.delete id
        updated.add id
      else
        added.add id
      end
    end

    def update(id)
      updated.add id unless added? id
    end

    def remove(id)
      if added? id
        added.delete id
      else
        updated.delete id
        removed.add id
      end
    end

    def revert(id)
      EVENTS.each { |e| changes[e].delete id }
    end

    EVENTS.each do |event|
      define_method "#{event}?" do |id|
        changes[event].include? id
      end
    end

    def to_h
      changes.to_h
    end
    alias_method :to_primitive, :to_h

    def dump
      EVENTS.each_with_object({}) do |e,h|
        h[e] = changes[e].dump unless changes[e].empty?
      end
    end

    def restore(dump)
      EVENTS.each { |e| changes[e].restore dump[e] }
    end

    def destroy
      EVENTS.each { |e| changes[e].destroy }
    end

    private

    attr_reader :changes

    EVENTS.each do |event|
      define_method event do
        changes[event]
      end
    end

  end
end