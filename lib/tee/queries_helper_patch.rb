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
	   	case column.name
	   	when column.name == :total_time
		    value = Issue.get_total_time(issue.id, @project)
		when column.name == :total_time_last_status
		    value = Issue.get_total_time_last_status(issue.id, @project)
		when "cf_#{Setting.plugin_tiempo_entre_estados[:tee_time_ans]}".to_sym
			start_statuses = issue.get_start_statuses_ans(issue)
			pause_statuses = issue.get_pause_statuses_ans(issue)
			intervals = issue.get_intervals

			start_statuses.each do |role, statuses_start|
				intervals.each do |interval|
					if @status_ans_id.include?(interval[:status_id]) && statuses_start.map{|s| s[:id]}.include?(interval[:status_id])
						time = TeeTimetable.get_total_time(issue.project_id, role, interval[:start], interval[:end])
						if time != 0
							time_hours = Issue.get_hours(time)
							if time_hours > 0.0
								# return Issue.get_seconds_to_hh_mm(time)
								return time.round.to_s
							end
						end
					end
				end
			end
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