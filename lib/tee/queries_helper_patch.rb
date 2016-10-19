require_dependency 'queries_helper'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

# Patches Redmine's ApplicationController dinamically. Redefines methods wich
# send error responses to clients
module TEE
	module QueriesHelperPatch
	  def self.included(base) # :nodoc:
	    base.extend(ClassMethods)
	    base.send(:include, InstanceMethods)

	    base.class_eval do
	      #unloadable  # Send unloadable so it will be reloaded in development
	      alias_method_chain :csv_content, :tee_total_time
	    end
	  end

	  module ClassMethods
	  end 

	  module InstanceMethods
	   def csv_content_with_tee_total_time(column, issue)
	    if column.name == :total_time
		    value = Issue.get_total_time(issue.id, @project)
		  else
		    value = column.value_object(issue)
		    if value.is_a?(Array)
		      value.collect {|v| csv_value(column, issue, v)}.compact.join(', ')
		    else
		      csv_value(column, issue, value)
	        end
		  end
		end
	  end
	end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    QueriesHelper.send(:include, TEE::QueriesHelperPatch)
  end
else
  Dispatcher.to_prepare do
    QueriesHelper.send(:include, TEE::QueriesHelperPatch)
  end
end