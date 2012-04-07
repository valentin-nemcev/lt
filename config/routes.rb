Lt::Application.routes.draw do

  root :to => 'pages#main'

  resources :tasks do
    post 'complete', :on => :member
    post 'undo_complete', :on => :member
  end

  resources :quotes do
    get 'next_random', :on => :collection
  end

end
