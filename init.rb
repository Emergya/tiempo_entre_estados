require 'tee/issue_status_patch'
require 'tee/project_patch'
require 'tee/role_patch'
require 'tee/application_helper_patch'
require 'tee/issue_patch'
require 'tee/issue_query_patch'
require 'tee/issues_controller_patch'
require 'tee/hooks_view_total_time_issue'
require 'tee/hooks_view_last_interval_time_issue'
require 'redmine/export/pdf_patch'
require 'tee/queries_helper_patch'

Redmine::Plugin.register :tiempo_entre_estados do
  name 'Tiempo Entre Estados plugin'
  author 'jresinas, mabalos'
  description 'Plugin que permite controlar el tiempo entre distintos estados, y donde se muestra el tiempo invertido entre dichos estados'
  version '0.2.0'
  author_url 'http://www.emergya.es'

  requires_redmine_plugin :adapter_deface, :version_or_higher => '0.0.1'

  project_module :tiempo_entre_estados do
    permission :tee_view_config, :tee => [:index]
    permission :tee_edit_statuses, :tee_prs => [:index, :create]
    permission :tee_edit_timetables, :tee_timetables => [:index, :create, :edit, :update, :destroy]
    permission :tee_edit_holidays, :tee_holidays => [:index, :create, :edit, :update, :destroy]
    permission :tee_view_time, :issues => [:stats_total_time]
  end
  
  menu :project_menu, :config_time_statuses, { :controller => 'tee', :action => 'index' }, :caption => 'Control de tiempos', :last => true, :param => :project_id

end
