Rails.application.config.assets.configure do |env|
  env.context_class.class_eval do
    include ActionView::Helpers
  end
end
