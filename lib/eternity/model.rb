module Eternity
  module Model

    def self.included(base)
      base.after_create do |model|
        check_current_session!
        Session.current[model.class.table_name].insert model.id, model.attributes
      end

      base.after_update do |model|
        check_current_session!
        Session.current[model.class.table_name].update model.id, model.attributes
      end

      base.after_destroy do |model|
        check_current_session!
        Session.current[model.class.table_name].delete model.id
      end
    end

    private

    def check_current_session!
      raise 'Undefined current session' unless Session.current
    end

  end
end