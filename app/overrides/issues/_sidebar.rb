Deface::Override.new :virtual_path  => 'issues/_sidebar',
                     :name          => 'sidebar_ans',
                     :original		=> 'eb636b64c80e811bdf4daf422bbdac01e14ac308',
                     :insert_after => "erb[loud]:contains(\"link_to l(:field_summary), project_issues_report_path(@project)\")",
                     :text          => '<li>
                     						<% if User.current.allowed_to?(:tee_report_ans, @project, :global => true) %>
                     						<%= link_to l(:report_ans), project_report_ans_path(@project) %>
                     						<% end %>
                     					</li>'