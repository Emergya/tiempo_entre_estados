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
      # Este método se usará para ver el tiempo total en el listado de las peticiones como una columna opcional disponible
      # al igual que para que se mostrado el tiempo total en formato PDF y SCV.
      def get_total_time(issue_id, project)
        @total_time = 0
        @last_interval_time = 0

        @issue = Issue.find issue_id if issue_id
          @start_statuses = {}
          all_statuses = IssueStatus.all.map{|s| { :id => s.id, :name => s.name}}

          Role.all.each do |role|
            role_statuses = role.roles_statuses(@issue.project_id)
            close_statuses = role_statuses[:pause] + role_statuses[:close]
            @start_statuses[role.id] = all_statuses.reject{|s| close_statuses.include?(s)}
          end 
          @intervals = @issue.get_intervals

          @start_statuses.each do |role, statuses|
           @intervals.each do |interval|
             # Calcula el tiempo total de todos los intervalos
               @total_time += TeeTimetable.get_total_time(@issue.project_id, role, interval[:start], interval[:end]) if statuses.map{|s| s[:id]}.include?(interval[:status_id])
           end
          end

          return Issue.get_hours(@total_time).round(1).to_s
      end

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