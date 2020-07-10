Rails.application.routes.draw do
  post '/callback' => 'line#callback'
end
