module Acceptance; end

module Acceptance::Task
  class Widget
    include Capybara::DSL
    def new_project_sn
      @project_sn = (@project_sn || 0) + 1
    end

    def initialize
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
      @node.find('[form=new-task], [form=update-task]').tap do |form|
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
      @node.matches_selector?('[record-state=persisted]')
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

    def selected?
      xpath = Nokogiri::CSS.xpath_for('> .task.selected').first
      @node.has_selector?(:xpath, xpath)
    end

    def select
      @node.find('[control=select]').click unless selected?
    end

    def update
      @node.find("[control=update]").click
    end

    def new_sub_task(fields = {})
      select
      @node.find('[control=new-subtask]').click
      sub_task_node = @node.find('[records=subtasks]')
        .find('[record=task][record-state=new]')
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
      @node.matches_selector?("[task-state='#{state}']")
    end
  end
end
