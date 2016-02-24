require_dependency 'application_helper'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module TEE
  module ApplicationHelperPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        def calendar_for_es(field_id)
		    include_calendar_headers_tags_es
		    javascript_tag("$(function() { $('##{field_id}').datepicker(datepickerOptions); });")
		end

		def include_calendar_headers_tags_es
	        unless @calendar_headers_tags_included
		      tags = javascript_include_tag("datepicker")
		      @calendar_headers_tags_included = true
		      content_for :header_tags do
		        start_of_week = Setting.start_of_week
		        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
		        # Redmine uses 1..7 (monday..sunday) in settings and locales
		        # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
		        start_of_week = start_of_week.to_i % 7
		        tags << javascript_tag(
		                   "var datepickerOptions={dateFormat: 'dd-mm-yy', firstDay: #{start_of_week}, " +
		                     "showOn: 'button', buttonImageOnly: true, buttonImage: '" +
		                     path_to_image('/images/calendar.png') +
		                     "', showButtonPanel: true, showWeek: true, showOtherMonths: true, " +
		                     "selectOtherMonths: true, changeMonth: true, changeYear: true, " +
		                     "beforeShow: beforeShowDatePicker};")
		        jquery_locale = l('jquery.locale', :default => current_language.to_s)
		        unless jquery_locale == 'en'
		          tags << javascript_include_tag("i18n/datepicker-#{jquery_locale}.js")
		        end
		        tags
		      end
		    end
		end
      end
    end

    module ClassMethods
      
    end

    module InstanceMethods
    end
  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    ApplicationHelper.send(:include, TEE::ApplicationHelperPatch)
  end
else
  Dispatcher.to_prepare do
    ApplicationHelper.send(:include, TEE::ApplicationHelperPatch)
  end
end