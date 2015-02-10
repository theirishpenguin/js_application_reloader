module JsApplicationReloader
  class InstallGenerator < Rails::Generators::Base

    TEMPLATE_FILENAME = 'js_application_reloader.rb'
    DESTINATION_FILEPATH = 'config/initializers/js_application_reloader.rb'

    desc "This generator creates an initializer file at #{DESTINATION_FILEPATH}"

    source_root File.expand_path("../../templates", __FILE__)

    def copy_initializer
      copy_file TEMPLATE_FILENAME, DESTINATION_FILEPATH
    end
  end
end
