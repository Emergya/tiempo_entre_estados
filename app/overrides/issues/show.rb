Deface::Override.new :virtual_path  => 'issues/show',
                     :name          => 'show_custom_fields_top',
                     :original		=> '6e9ee74a4999a775f37d6dd5609bd74408496d95',
                     :insert_before => "erb[loud]:contains(\"render_custom_fields_rows(@issue)\")",
                     :text          => '<%= call_hook(:view_issues_show_custom_fields_top) %>'

