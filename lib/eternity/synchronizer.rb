module Eternity
  class Synchronizer

    BATCH_SIZE = 1000

    class << self

      def apply(delta)
        ActiveRecord::Base.transaction do
          to_sql(delta).each_slice(BATCH_SIZE) do |sentences|
            ActiveRecord::Base.connection.execute sentences.join(";\n")
          end
        end
      end

      private

      def to_sql(delta)
        delta.each_with_object([]) do |(collection, changes), sentences|
          changes.each do |id, change|
            action = change['action']
            args = [collection, id, change['data']].compact
            sentences << send("#{action}_sql", *args)
          end
        end
      end

      def insert_sql(collection, id, data)
        columns = data.keys.join(', ')
        values = data.values.map { |v| value_to_sql v }.join(', ')

        "INSERT INTO #{collection} (#{columns}) VALUES (#{values})"
      end

      def update_sql(collection, id, data)
        columns = data.keys.reject { |k| k == 'id' }.join(', ')
        values = data.reject { |k,v| k == 'id' }.map { |k,v| value_to_sql v }.join(', ')

        assignments = data.reject { |k,v| k == 'id' }.map do |key, value|
          "#{key} = #{value_to_sql value}"
        end.join(', ')

        "UPDATE #{collection} SET #{assignments} WHERE id = #{value_to_sql id}"
      end

      def delete_sql(collection, id)
        "DELETE FROM #{collection} WHERE id = #{value_to_sql id}"
      end

      def value_to_sql(value)
        ActiveRecord::Base.connection.visitor.accept value
      end

    end
  end
end