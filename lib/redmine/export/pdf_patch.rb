require_dependency 'redmine/export/pdf'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module Redmine
  module Export
    module PDFPatch
	    def self.included(base) # :nodoc:
	      base.extend(ClassMethods)
	      base.send(:include, InstanceMethods)

	      # Same as typing in the class
	      base.class_eval do
	        unloadable # Send unloadable so it will be reloaded in development
	        alias_method_chain :fetch_row_values, :tee_total_time
	        
	      end
	    end

	    module ClassMethods
	    end

	    module InstanceMethods
	      def fetch_row_values_with_tee_total_time(issue, query, level)
			query.inline_columns.collect do |column|
	          s = if column.is_a?(QueryCustomFieldColumn)
	            cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
	            show_value(cv, false)
	          else
	          	if column.name == :total_time
	          		value = Issue.get_total_time(issue.id, @project)+" hora(s)"
	          	elsif column.name == :total_time_last_status
	          		value = Issue.get_total_time_last_status(issue.id, @project)+" hora(s)"
	          	else
		            value = issue.send(column.name)
		            if column.name == :subject
		              value = "  " * level + value
		            end
		            if value.is_a?(Date)
		              format_date(value)
		            elsif value.is_a?(Time)
		              format_time(value)
		            else
		              value
		            end
	          	end
	          end
	          s.to_s
	        end
	      end
	    end
	end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    Redmine::Export::PDF.send(:include, Redmine::Export::PDFPatch)
  end
else
  Dispatcher.to_prepare do
    Redmine::Export::PDF.send(:include, Redmine::Export::PDFPatch)
  end
end