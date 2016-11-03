require_dependency 'issues_controller'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module TEE
	module IssuesControllerPatch
	  def self.included(base) # :nodoc:
	    base.extend(ClassMethods)
	    base.send(:include, InstanceMethods)
	    base.class_eval do
	      unloadable  # Send unloadable so it will be reloaded in development
	      alias_method_chain :show, :total_time
	      before_filter :find_project_by_project_id, :only => [:stats_total_time, :report_ans]
	      before_filter :set_start_statuses, :set_get_intervals, only: [:show, :stats_total_time]
	      before_filter :set_pause_statuses, :set_get_intervals, only: [:show, :stats_total_time]
	      skip_before_filter :authorize, :only => [:stats_total_time, :report_ans]
	      menu_item :issues, :only => [:stats_total_time, :report_ans]
	    end
	  end

	  module InstanceMethods
		# Calcula el tiempo total en horas de una peticion.
		def show_with_total_time
			@total_time = 0
			@last_interval_time = 0

			@start_statuses.each do |role, statuses|
			 @intervals.each do |interval|
			 	 # Calcula el tiempo total de todos los intervalos
			     @total_time += TeeTimetable.get_total_time(@issue.project_id, role, interval[:start], interval[:end]) if statuses.map{|s| s[:id]}.include?(interval[:status_id])

			     # Calcula el tiempo del ultimo intervalo
			 	 if interval == @intervals.last
			 	 	@last_interval_time += TeeTimetable.get_total_time(@issue.project_id, role, interval[:start], interval[:end]) if statuses.map{|s| s[:id]}.include?(interval[:status_id])
			 	 end
			 end
			end

			@total_time = Issue.get_hours(@total_time) 
			@last_interval_time = Issue.get_hours(@last_interval_time)

		    show_without_total_time
		end

	   	# Recoge toda la información para cada intervalo de una petición
		def stats_total_time
				if User.current.allowed_to?(:tee_view_time, @project)
					@stats_time = []
		   		@time_by_roles = {}

				# Muestra el tiempo de los estados de inicio de cada perfil
				@start_statuses.each do |role, statuses_start|
				@intervals.each do |interval|
			    	if statuses_start.map{|s| s[:id]}.include?(interval[:status_id])
				    	time = TeeTimetable.get_total_time(@issue.project_id, role, interval[:start], interval[:end])
					    if time != 0
						    role_selected = Role.find role
						    time_hours = Issue.get_hours(time)
						    time_hh_mm_ss = Issue.get_seconds_to_hh_mm(time)

						    if interval[:user_id].present?
						    	user_name = User.find(interval[:user_id])
						    	user = user_name.firstname + "-" + user_name.lastname
						    else
						    	user ="-"
						    end
			
						    # @stats_time << {:role => role_selected.name, :status => IssueStatus.find(interval[:status_id])[:name], :user => user,:start => interval[:start], :end => interval[:end], :time => time_hours} if time_hours > 0.0
						    @stats_time << {:role => role_selected.name, :status => IssueStatus.find(interval[:status_id])[:name], :user => user,:start => interval[:start], :end => interval[:end], :time => time_hh_mm_ss} if time_hours > 0.0

						    @time_by_roles[role_selected.name] ? @time_by_roles[role_selected.name] += time_hours : @time_by_roles[role_selected.name] = time_hours
					 	end	
				    end
				end
			end    

				# Muestra el tiempo de los estados de pausa del perfil (aparecerá 0.0 horas)
				@pause_statuses.each do |role, statuses_pause|
					@intervals.each do |interval|
		   			if statuses_pause.map{|s| s[:id]}.include?(interval[:status_id])
				   		role_selected = Role.find role

				   		if interval[:user_id].present?
					    	user_name = User.find(interval[:user_id])
					    	user = user_name.firstname + "-" + user_name.lastname
					    else
					    	user ="-"
					    end

					    # @stats_time << {:role => role_selected.name, :status => IssueStatus.find(interval[:status_id])[:name], :start => interval[:start], :end => interval[:end], :time => 0.0}
					    @stats_time << {:role => role_selected.name, :status => IssueStatus.find(interval[:status_id])[:name], :user => user, :start => interval[:start], :end => interval[:end], :time => "00 horas, 00 minutos"}
		   			end
					end
				end

				# Ordenamos el array de hashes para que nos muestre los tiempos de estados ordenados por fecha
				@stats_time.sort_by!{ |stats| stats[:start] }

				render 'stats_total_time.html.erb'
		 else
		   deny_access
		 end
		end

		# Recoge los estados con los que debe de contar el tiempo
		# Que son todos los estados menos los estados de pausa y los estados de fin
		def set_start_statuses
			@issue = Issue.find params[:issue_id] if params[:issue_id]
			@start_statuses = {}
			all_statuses = IssueStatus.all.map{|s| { :id => s.id, :name => s.name}}

			Role.all.each do |role|
				role_statuses = role.roles_statuses(@issue.project_id)
				close_statuses = role_statuses[:pause] + role_statuses[:close]
				@start_statuses[role.id] = all_statuses.reject{|s| close_statuses.include?(s)}
			end	
		end

		def set_pause_statuses
			@issue = Issue.find params[:issue_id] if params[:issue_id]
			@pause_statuses = {}
			all_statuses = IssueStatus.all.map{|s| { :id => s.id, :name => s.name}}

			Role.all.each do |role|
				role_statuses = role.roles_statuses(@issue.project_id)
				@pause_statuses[role.id] = role_statuses[:pause]
			end	
		end

		def set_get_intervals
			@intervals = @issue.get_intervals
		end

		def report_ans
			render 'ans.html.erb'
		end

	  end

	  module ClassMethods
	  end
	end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    IssuesController.send(:include, TEE::IssuesControllerPatch)
  end
else
  Dispatcher.to_prepare do
    IssuesController.send(:include, TEE::IssuesControllerPatch)
  end
end