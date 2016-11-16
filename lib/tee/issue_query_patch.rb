module TEE
  module IssueQueryPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        alias_method_chain :available_columns, :tee_total_time
      end
    end

    module ClassMethods
    end

    module InstanceMethods

    	def available_columns_with_tee_total_time
		    return @available_columns if @available_columns
		    @available_columns = self.class.available_columns.dup
		    @available_columns += (project ?
		                            project.all_issue_custom_fields :
		                            IssueCustomField
		                           ).visible.collect {|cf| QueryCustomFieldColumn.new(cf) }

		    if User.current.allowed_to?(:view_time_entries, project, :global => true)
		      index = nil
		      @available_columns.each_with_index {|column, i| index = i if column.name == :estimated_hours}
		      index = (index ? index + 1 : -1)
		      # insert the column after estimated_hours or at the end
		      @available_columns.insert index, QueryColumn.new(:spent_hours,
		        :sortable => "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)",
		        :default_order => 'desc',
		        :caption => :label_spent_time
		      )
		    end

		    if User.current.allowed_to?(:set_issues_private, nil, :global => true) ||
		      User.current.allowed_to?(:set_own_issues_private, nil, :global => true)
		      @available_columns << QueryColumn.new(:is_private, :sortable => "#{Issue.table_name}.is_private")
		    end

		    @available_columns << QueryColumn.new(:total_time, :name => "Tiempo total")
		    @available_columns << QueryColumn.new(:total_time_last_status, :name => "Tiempo estado actual")

		    disabled_fields = Tracker.disabled_core_fields(trackers).map {|field| field.sub(/_id$/, '')}
		    @available_columns.reject! {|column|
		      disabled_fields.include?(column.name.to_s)
		    }

		    @available_columns
		end

    end

  end
end
if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    IssueQuery.send(:include, TEE::IssueQueryPatch)
  end
else
  Dispatcher.to_prepare do
    IssueQuery.send(:include, TEE::IssueQueryPatch)
  end
end