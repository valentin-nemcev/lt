Lt::Application.routes.draw do

  root :to => 'pages#main'

  resources :tasks

  resources :quotes do
    get 'next_random', :on => :collection
  end

end
