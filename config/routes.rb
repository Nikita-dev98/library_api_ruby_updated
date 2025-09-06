Rails.application.routes.draw do
  resources :books do
    # extra routes nested under books
    member do
      post :borrow   # /books/:id/borrow
    end

    collection do
      get :search    # /books/search
      post :series_availability  # /books/series_availability
    end
  end
end
