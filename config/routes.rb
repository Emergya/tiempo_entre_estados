# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
	scope '/projects/:project_id/', :as => "project" do
		match 'tiempo_entre_estados', to: 'tee#index', as: 'tee_home'
		
		#match ':role_id/statuses', to: 'tee_prs#index'
		#match ':role_id/statuses/:action', to: 'tee_prs'
		scope ':role_id/' do
			resources :statuses, :controller => 'tee_prs', :as => 'tee_prs'
		end

		resources :timetables, :controller => 'tee_timetables', :as => 'tee_timetables' do
			resources :tee_timetables_journals
		end
		resources :holidays, :controller => 'tee_holidays', :as => 'tee_holidays'

		match '/issues/ans', :controller => 'issues', :action => 'report_ans', as: 'report_ans'
	end


	match '/issues/:issue_id/stats_total_time', to: 'issues#stats_total_time', as: 'stats_total_time'
end