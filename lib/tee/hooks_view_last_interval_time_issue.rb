class HooksViewLastIntervalTimeIssue < Redmine::Hook::ViewListener
  render_on :view_issues_show_custom_fields_top, :partial => "issues/last_interval_time"
end