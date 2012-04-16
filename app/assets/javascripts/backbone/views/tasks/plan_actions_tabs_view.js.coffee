Views = Lt.Views.Tasks ||= {}

class Views.PlanActionsTabsView extends Lt.Views.TabsView
  template: JST['backbone/templates/tasks/plan_actions_tabs']

  stateAttr: 'current_tab'
