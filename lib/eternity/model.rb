module Eternity
  module Model

    def self.included(base)
      base.after_create do |model|
        check_current_repository!
        Repository.current[model.class.table_name].insert model.id, model.attributes
      end

      base.after_update do |model|
        check_current_repository!
        Repository.current[model.class.table_name].update model.id, model.attributes
      end

      base.after_destroy do |model|
        check_current_repository!
        Repository.current[model.class.table_name].delete model.id
      end
    end

    private

    def check_current_repository!
      raise 'Undefined current repository' unless Repository.current
    end

  end
end