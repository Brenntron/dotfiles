# Be sure to restart your server when you modify this file.

# Rails.application.config.session_store :cookie_store, key: '_api_session'
Rails.application.config.session_store :cookie_store, key: "_#{Rails.configuration.app_name}_session"
# Rails.application.config.session_store :cookie_store, key: '_analyst_console_escalations_session'
