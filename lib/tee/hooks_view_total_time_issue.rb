class HooksViewTotalTimeIssue < Redmine::Hook::ViewListener
  render_on :view_issues_show_custom_fields_top, :partial => "issues/total_time"
end