require_dependency 'issue'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module TEE
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
      end
    end

    module ClassMethods
      def get_hours(seconds)
        return ((seconds.to_f/60.0)/60.0)
      end
    end

    module InstanceMethods
      def get_intervals
        result = []
        journals = JournalDetail.joins(:journal).select("journal_details.old_value, journal_details.value, journals.created_on AS end").where('journals.journalized_id = ? AND prop_key = ?', self.id, 'status_id')

        start = Issue.select('created_on AS start').find(self.id).start.to_datetime

        if journals.present?
          journals.each do |journal|
            result << {:status_id => journal.old_value.to_i, :start => start, :end => journal.end.to_datetime}
            start = journal.end.to_datetime
          end
        end
          result << {:status_id => self.status_id, :start => start, :end => Time.now}
      end
    end

  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    Issue.send(:include, TEE::IssuePatch)
  end
else
  Dispatcher.to_prepare do
    Issue.send(:include, TEE::IssuePatch)
  end
end