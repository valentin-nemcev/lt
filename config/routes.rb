Lt::Application.routes.draw do

  root :to => 'pages#main'

  resources :ui_states, :only => [:show, :update]

  resources :tasks do
    post 'complete', :on => :member
    post 'undo_complete', :on => :member
  end

  match 'users/select' => 'users#select', :via => :post, :as => :select_user

end
