module Eternity
  class ConflictResolver

    Diff = Struct.new :added, :updated, :removed

    attr_reader :current, :target, :base
    
    def initialize(current, target, base={})
      @current = current
      @target = target
      @base = base
    end

    def resolve
      current_diff = diff current, base
      target_diff = diff target, base
      merge(target_diff, target, merge(current_diff, current, base))
    end

    def self.resolve(current, target, base={})
      new(current, target, base).resolve
    end

    private

    def diff(object, base)
      Diff.new object.keys - base.keys,
               base.keys.select { |k| base[k] != object[k] },
               base.keys - object.keys
    end

    def merge(diff, object, base)
      base.dup.tap do |result|
        (diff.added + diff.updated).each { |k| result[k] = object[k] }
        diff.removed.each { |k| result.delete k }
      end
    end

  end
end