JsApplicationReloader.configure do |config|

  # Leave async_js_project is false for projects that don't asynchronously load their Javascript
  # Set it to true if you use libraries such as RequireJS which do load asynchronously
  config.async_js_project = false

  # Here we determine the value of the token, which is set every time the Rails server is (re)started.
  # A change in value of this token indicates that the application needs to be reloaded.
  #
  # Examples
  # * Time.now.to_i - The JS will be reloaded every time the Rails server is restarted
  # * File.stat("./dist").mtime.to_i - The JS will be reloaded every time the Rails
  #   server is restarted AND the modified time of the public/dist directory is updated
  config.token = Time.now.to_i # eg. File.stat("./public/dist").mtime.to_i

  # Name of the header that holds the current value of the token sent from the client to the server
  config.token_header_name = "X-Js-Application-Reloader-Current-Token"

  # The http status code that the server sends back to the client with when a reload is required
  config.reload_required_http_status = 200;

  # Name of the header that the server sends back to the client with the response which indicates if a reload is required
  config.status_header_name = "X-Js-Application-Reloader-Status"

  # Let's you customize the expiration message with your application name
  config.application_name = 'this application'

  # Let's you customize the expiration message with a link to go to in order to reload the front end of the application
  config.redirect_url = '/users/sign_in'

end
