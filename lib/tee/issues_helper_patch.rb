require_dependency 'issues_helper'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

# Patches Redmine's ApplicationController dinamically. Redefines methods wich
# send error responses to clients
module TEE
	module IssuesHelperPatch
	  def self.included(base) # :nodoc:
	    base.extend(ClassMethods)
	    base.send(:include, InstanceMethods)

	    base.class_eval do
	      #unloadable  # Send unloadable so it will be reloaded in development
	      alias_method_chain :query_links, :ans
	    end
	  end

	  module ClassMethods
	  end 

	  module InstanceMethods
	   	def query_links_with_ans(title, queries)
		    return '' if queries.empty?
		    content_tag('h3', title) + "\n" +
		      content_tag('ul',
		        queries.collect {|query|    		
						    # links to #index on issues/show
						    if query.filters.include?("cf_#{Setting.plugin_tiempo_entre_estados[:tee_status_ans]}")
						    	url_params = controller_name == 'issues' ? {:controller => 'issues', :action => 'report_ans', :project_id => @project} : params
						    else
						    	url_params = controller_name == 'issues' ? {:controller => 'issues', :action => 'index', :project_id => @project} : params
						    end
		            css = 'query'
		            css << ' selected' if query == @query
		            content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
		          }.join("\n").html_safe,
		        :class => 'queries'
		      ) + "\n"
		  end
		end
	end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    IssuesHelper.send(:include, TEE::IssuesHelperPatch)
  end
else
  Dispatcher.to_prepare do
    IssuesHelper.send(:include, TEE::IssuesHelperPatch)
  end
end