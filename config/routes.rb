require "resque_web"

Rails.application.routes.draw do

  get 'admin_sections/index'

  get 'admin_sections/list_users'

  get 'admin_sections/edit_user'

  devise_for :users
  

  mount ResqueWeb::Engine => "/resque_web"

  resources :correlations
  resources :correlation_collections
  resources :asset_types
  resources :asset_types

  resources :simulations, except: [:show, :update]
  post 'simulations/run_simulation' => 'simulations#run_simulation'
  
  get 'simulations/manage' => 'simulations#manage'
  get 'simulation' => 'simulations#index'
  get 'simulations/results' => 'simulations#results'
  post 'simulations/results' => 'simulations#results'
  patch 'simulations/results' => 'simulations#results'
  get 'simulations/matrix_test' => 'simulations#matrix_test'
  get 'simulations/sources' => 'simulations#sources'
  get 'simulations/build_simulation' => 'simulations#build_simulation'


  root 'simulations#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
