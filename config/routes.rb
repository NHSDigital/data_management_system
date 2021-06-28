Rails.application.routes.draw do
  mount NdrError::Engine => '/fingerprinting'
  mount NdrAuthenticate::Engine, at: '/auth' if Rails.configuration.x.use_ndr_authenticate

  get '/users/sign_in', to: redirect('/auth/sign_in') if Rails.configuration.x.use_ndr_authenticate

  # NOTE: NdrAuth cannot at present pick up a custom `after_sign_in_path_for` defined by the
  # host app. Since it will always redirect to `main_app.root_path` we can instead change what
  # controller/action the host app understands '/' to be for different contexts and achieve a
  # similar result.
  authenticated :user, ->(user) { !user.standard? } do
    root 'projects#dashboard', as: :non_standard_authenticated_root
  end

  authenticated :user, ->(user) { user.cas_role? } do
    root 'projects#index', as: :cas_role_authenticated_root
  end

  authenticated :user, ->(user) { user.standard? && !user.cas_role? } do
    root 'home#index', as: :applicant_authenticated_root
  end

  root 'home#index'

  concern :downloadable do
    get :download, on: :member
  end

  concern :commentable do |options|
    defaults = {
      shallow: true,
      only:    %i[index create destroy]
    }

    resources :comments, defaults.merge(options)
  end

  concern :approvable do |options|
    default_options = {
      only: %i[new create destroy]
    }

    resource :approval,  default_options.merge(options)
    resource :rejection, default_options.merge(options)
  end

  get 'notifications/index'
  get '/reports/report1', to: 'reports#report1', as: 'report1'
  get '/reports/report2', to: 'reports#report2', as: 'report2'

  resources :reports, only: %i[show]

  get '/downloads/data_access_agreement', to: 'downloads#data_access_agreement',
                                          as: 'data_access_agreement'
  get '/downloads/ons_declaration_of_use', to: 'downloads#ons_declaration_of_use',
                                           as: 'ons_declaration_of_use'
  get '/downloads/ons_short_declaration_list', to: 'downloads#ons_short_declaration_list',
                                               as: 'ons_short_declaration_list'
  get '/downloads/terms_and_conditions_doc', to: 'downloads#terms_and_conditions_doc',
                                         as: 'terms_and_conditions_doc'
  get '/downloads/project_end_users_template_csv', to: 'downloads#project_end_users_template_csv',
      as: 'project_end_users_template_csv'

  # for dynamic select boxes in team and user
  get 'filter_delegates_by_division', to: 'users#filter_delegates_by_division',
                                      as: 'filter_delegates_by_division'

  get 'ons_template', to: 'projects#ons_template'

  # TODO: Remove once NdrAuthenticate is ready for the prime time.
  unless Rails.configuration.x.use_ndr_authenticate
    devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' },
                       skip: :saml_authenticatable
  end

  resources :notifications, :directorates, :divisions

  resources :users do
    resources :grants, only: [:index] do
      collection do
        get :edit_team
        get :edit_system
        get :edit_project
        get :edit_dataset
        patch :update
      end
    end
    get :teams
    get :projects
  end

  resources :projects do
    get :dashboard, on: :collection
    get :cas_approvals, on: :collection
  end

  resources :projects, shallow: true do
    resources :project_datasets, shallow: true do
      resources :project_dataset_levels do
        collection do
          patch :update
        end
        member do
          patch :approve
          put :approve
          patch :reapply
          put :reapply
        end
      end
    end
  end

  resources :home, only: [:index]

  resources :terms_and_conditions, only: [:index, :create]

  resources :active_team, only: [:index, :update]

  resources :data_sources, shallow: true do
    resources :data_source_items
  end

  resources :table_specifications, only: [:index]
  resources :data_assets, only: [:index]
  resources :datasets, shallow: true do
    resources :dataset_versions, shallow: true do
      resources :categories
      resources :nodes do
        collection do
          patch :sort
        end
        resources :node_categories do
          collection do
            patch :update
          end
        end
      end
      resources :data_items do
        member do
          get :edit_error, to: 'data_items#edit_error', as: :edit_error
          patch :edit_error, to: 'data_items#update_error', as: :update_error
        end
      end
      resources :entities do
        member do
          get :edit_error, to: 'entities#edit_error', as: :edit_error
          patch :edit_error, to: 'entities#update_error', as: :update_error
        end
      end
      resources :choices do
        member do
          get :edit_error, to: 'choices#edit_error', as: :edit_error
          patch :edit_error, to: 'choices#update_error', as: :update_error
        end
      end
      resources :groups do
        member do
          get :edit_error, to: 'groups#edit_error', as: :edit_error
          patch :edit_error, to: 'groups#update_error', as: :update_error
        end
      end
      resources :category_choices, :node_errors
      patch :publish, on: :member
      get "download/:id" => "dataset_versions#download", as: :download
    end
  end

  resources :user_notifications
  patch :mark_notification_as_read, to: 'user_notifications#mark_as_read'

  resources :organisations, shallow: true do
    resources :teams
  end

  patch :default_address, to: 'addresses#default_address'

  resources :teams, shallow: true, except: %i[new create] do
    resources :datasets
    resources :memberships
    resources :grants, controller: :team_grants do
      collection do
        get :edit
        patch :update
      end
    end
    resources :team_datasets, only: [:index, :new, :create, :destroy]
    resources :projects, shallow: true, concerns: %i[commentable] do
      resources :grants, controller: :project_grants do
        collection do
          get :edit
          patch :update
        end
      end
      resources :project_memberships, only: [:index, :new, :create, :destroy]
      resources :project_data_end_users
      resources :project_attachments

      resources :project_nodes, except: %i[edit update], concerns: %i[commentable] do
        concerns :approvable, module: 'project_nodes'

        collection do
          scope :bulk, module: :project_nodes, only: %i[new create destroy] do
            resource :approvals,  controller: :bulk_approvals,  as: :project_nodes_bulk_approval
            resource :rejections, controller: :bulk_rejections, as: :project_nodes_bulk_rejection
          end
        end
      end

      resources :amendments, controller: :project_amendments, as: :project_amendments
      resources :data_privacy_impact_assessments, concerns: %i[downloadable]
      resources :contracts, concerns: %i[downloadable]
      resources :releases
      resources :communications, except: %i[show edit update], concerns: %i[commentable]

      namespace :workflow do
        resources :project_states, only: [] do
          concerns :commentable, controller: '/comments'
          resources :assignments, only: %i[create]
        end
      end

      collection do
        post :import
      end

      resource :details, only: [], concerns: %i[approvable], module: 'projects/details'
      resource :legal,   only: [], concerns: %i[approvable], module: 'projects/legal'
      resource :members, only: [], concerns: %i[approvable], module: 'projects/members'

      member do
        # FIXME: This should be PATCH
        get :reset_project_approvals
        get :edit_data_source_items
        get :edit_ons_data_access
        get :edit_ons_declaration
        get :show_ons_access_agreement
        get :show_ons_declaration_use
        get :show_ons_declaration_list
        get :duplicate
        patch :assign
        patch :transition
      end
    end
  end

  resources :jobs, only: %i[index show destroy]

  get '/terms_rejected', to: 'terms_and_conditions#terms_rejected', as: 'terms_rejected'

  get ':resource_type/:resource_id/versions',     to: 'versions#index', as: :papertrail_versions
  get ':resource_type/:resource_id/versions/:id', to: 'versions#show',  as: :papertrail_version

  # Allowing logged-in user to change their password:
  get  'change_password', to: 'users/password_changes#new'
  post 'change_password', to: 'users/password_changes#create'
end
