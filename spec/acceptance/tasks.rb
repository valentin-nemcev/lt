module Acceptance; end

module Acceptance::Task
  module Helpers
    def visit_unless_current(path)
      visit(path) unless current_path == path
    end

    def reload_page
      visit current_path
    end
  end

  PAGE_PATH = '/'
  class Widget
    include Capybara::DSL
    include Helpers
    def new_project_sn
      @project_sn = (@project_sn || 0) + 1
    end


    def initialize
      visit_unless_current PAGE_PATH
      @node = find('[widget=tasks]')
    end

    def new_project(fields = {})
      new_task fields.reverse_merge(type: 'project',
                            objective: "Project #{new_project_sn}")
    end

    def new_task(fields = {})
      @node.find('[control=new]').click
      task_node = @node.find('[record=task][record-state=new]')
      Record.new(node: task_node).tap do |task_record|
        task_record.fill_form fields
        task_record.persisted? or fail 'Task was not created'
      end
    end

  end

  class Record
    def initialize(opts = {})
      @node = opts[:node]
    end

    def fill_form(fields={})
      task_node.find('[form=new-task], [form=update-task]').tap do |form|
        fields[:type].try{ |type| form.find('[input=type]').set_option type }
        fields[:state].try{ |state|
          form.find('[input=state]').set_option state
        }
        fields[:objective].try{ |objective|
          form.find('[input=objective]').set objective
        }
        form.find('[control=save]').click
      end
    end

    def persisted?
      @node.session.wait_until do
        @node['record-state'] == 'persisted'
      end
    end

    def new_project_sn
      @project_sn = (@project_sn || 0) + 1
    end

    def new_action_sn
      @action_sn = (@action_sn || 0) + 1
    end

    def new_sub_project(fields = {})
      new_sub_task fields.reverse_merge(type: 'project',
                                objective: "Project #{new_project_sn}")
    end

    def new_sub_action(fields = {})
      new_sub_task fields.reverse_merge(type: 'action',
                                objective: "Action #{new_action_sn}")
    end

    def subtasks_node
      return @subtasks_node if @subtasks_node
      xpath = Nokogiri::CSS.xpath_for('> [records="subtasks"]').first
      @subtasks_node = @node.find :xpath, xpath
    end

    def task_node
      return @task_node if @task_node
      xpath = Nokogiri::CSS.xpath_for('> .task').first
      @task_node = @node.find :xpath, xpath
    end

    def select
      task_node.has_selector?('[control=select]') and
        task_node.find('[control=select]').click
    end

    def update
      task_node.find("[control=update]").click
    end

    def new_sub_task(fields = {})
      select
      task_node.find('[control=new-subtask]').click
      sub_task_node = subtasks_node.find('[record=task][record-state=new]')
      Record.new(node: sub_task_node).tap do |sub_task_record|
        sub_task_record.fill_form fields
        sub_task_record.persisted? or fail 'Sub-task was not created'
      end
    end

    def update_state(state)
      select
      update
      fill_form state: state
    end

    def has_state?(state)
      @node.session.wait_until do
        @node['task-state'] == state
      end
    end

    def inspect
      attrs = %w{id record-id record-state task-type task-state}.map do |el|
        "#{el}=#{@node[el]}"
      end.join(' ')
      "#<task element: #{attrs}>"
    end
  end
end
