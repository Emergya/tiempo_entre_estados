require_dependency 'role'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module TEE
  module RolePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development

        has_many :tee_prss
        has_many :projects, :through => :tee_prss
        has_many :statuses, :through => :tee_prss, :class_name => 'IssueStatus', :foreign_key => :status_id
      end
    end

    module ClassMethods
      
    end

    module InstanceMethods
      # def all_statuses
      #   result = {}
      #   result['start'] = []
      #   result['pause'] = []
      #   result['close'] = []
      #   self.statuses.each do |status|
      #     result[status.type] << [status.id, status.name] 
      #   end

      #   result
      # end
    end
  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    Role.send(:include, TEE::RolePatch)
  end
else
  Dispatcher.to_prepare do
    Role.send(:include, TEE::RolePatch)
  end
end