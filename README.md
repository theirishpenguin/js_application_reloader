# JsApplicationReloader

# tl;dr
Timestamps on your JS, CSS and other assets get bumped to ensure that your
Javascript application is always running against the latest front-end code
exposed by the server. But what happens if the user doesn't browse off your
Single Page Application...

# Goal
JsApplicationReloader is a gem for enabling you to force the reload of a Single
Page Applications Javascript (SPA) in production. It is useful for Rails
applications which write an initial fragment of JSON into the Javascript to
configure the application. Traditionally it has been hard to expire this part of
the application's JS, along with the timestamps used in asset URLs such as
Javascript and CSS includes.

# How does it work?

Every time the rails server is restarted, a token (usually a timestamp) is
recorded on the server. This token is also written into the JSON fragment that
is rendered when the SPA is first loaded. Subsequent AJAX requests from the
front end send this token as an application specific header, which is compared
with the token recorded on the server. If these don't match it means the
server's Javascript has changed. This tells the server to send a token expired
header back to the client, along with some HTML. The client detects the token
expired header and displays the HTML to the user. This HTML contains a link
that the user can user to refresh the application. Simples!


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'js_application_reloader'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install js_application_reloader

## Usage

After you install JsApplicationReloader and add it to your Gemfile, you need to
run the generator:

    $ rails generate js_application_reloader:install

This will generate a file under
config/initializers/js_application_reloader.rb which you can customise.

Now is a good time to go and read that file for further details.

Then in your ApplicationController include the following line

    include JsApplicationReloader::ControllerExtensions

... this will add a before filter to your controllers which checks
whether the token is stale. It is recommended to put this line just
after any authentication/authorisation before filters.

In your app/views/layouts/application.html.erb file (or equivalent) include the
line

    <%=raw JsApplicationReloader::inject_script %>

This will include the token and some Javascript code on your page.

Optionally you can use JsApplicationReloader to manage the expiration of
your stylesheet and javascript includes, eg.

    <%= stylesheet_link_tag "/dist/stylesheets/application.css?version=#{JsApplicationReloader.token}" %>
    <%= javascript_include_tag "/dist/javascriptions/main.css?version=#{JsApplicationReloader.token}" %>

**Note: If you choose to use JsApplicationReloader to manage the expiration
of your stylesheet and javascript includes, then ensure you include the
```<%=raw JsApplicationReloader::inject_script %>``` line before the stylesheet
and JS includes.**

## Basic configuration for simple jQuery projects (ie. synchronous Javascript)

You need to manually call the token expiration code in your callbacks, eg.

      $.get(url, function(data, status, xhr) {
        // You need to add these 3 lines
        if (JsApplicationReloader.isTokenExpired(xhr)) {
          return JsApplicationReloader.handleTokenExpiration(xhr);
        }
        // your normal callback handler code goes here...
      });


## Basic configuration for AMD/RequireJS projects (ie. asynchronous Javascript)

This requires 3 steps.

1) In config/initializers/js_application_reloader.rb you need to set
```config.async_js_project = true```.

2) Configure application requests. You need to manually add some ajaxSend()
configuration to your application's JS codebase. Where you add this code depends
on what front-end MVC framework you are using, if any.

In BackboneJS you would insert this into the application's startup code, for example in application.js file. The only requirement is that Backbone is initialised.


    // -- Wireup AJAX send calls --
    $(document).ready(function() {
        $(document).ajaxSend(function(event, request) {
            if (JsApplicationReloader && JsApplicationReloader.token) {
                request.setRequestHeader(JsApplicationReloader.tokenHeaderName, JsApplicationReloader.token);
           }
        });
    });

3) Configure application response handling. Again this depends on what front-end
MVC framework you are using.

In BackboneJS you would insert this into the application's startup code, for example in application.js file. The only requirement is that Backbone is initialised.

    // -- Override Backbone sync() to handle expiration on success or error
    // -- Do the equivalent for your chosen framework
    var oldSyncMethod = Backbone.sync;
    Backbone.sync = function(method, model, options) {
        var oldSuccess = options.success;                                 
        options.success = function(data, textStatus, xhr) {               
            if (JsApplicationReloader.isTokenExpired(xhr)) {              
                return JsApplicationReloader.handleTokenExpiration(xhr);    
            } else if (oldSuccess) {                                      
                oldSuccess(data, textStatus, xhr);                        
            }                                                                                                    
        };    

        var oldError = options.error;
        options.error = function(xhr, textStatus, errorThrown) {
            // These are the important 3 lines
            if (JsApplicationReloader.isTokenExpired(xhr)) {
                return JsApplicationReloader.handleTokenExpiration(xhr);
            }
            if (oldError) { oldError(xhr, textStatus, errorThrown); }
        };
        return oldSyncMethod(method, model, options);
    };

**What about AJAX requests where I bypass the front-end MVC framework (eg. plain old jQuery AJAX requests)?**

As these don't go through the MVC framework's machinary you need to manually
call the token expiration code in your request callbacks. This has to be done
everywhere that you skip going through your MVC framework. eg.

      $.get(url, function(data, status, xhr) {
        // You need to add these 3 lines
        if (JsApplicationReloader.isTokenExpired(xhr)) {
          return JsApplicationReloader.handleTokenExpiration(xhr);
        }
        // your normal callback handler code goes here...
      });

# How do I know it worked?
Assuming that you are using the default strategy of reloading your application
when the server is restarted (ie. ```config.token = Time.now.to_i```)
then the following steps with verify it's working.

1. Start your server
2. Browse to a page that makes an AJAX request
3. Optional - if you inspect the request headers (eg. in Chrome's Network tab) you
   should see a header that looks like "X-Js-Application-Reloader-Current-Token".
   If not, then something went wrong when installing or configuring.
4. Stay on the same page in your Single Page Application
5. Restart the server and wait for it to be fully up and running
6. Without reloading the page, carry out an action that causing another AJAX
   request
7. If everything is working you should see "A new version of this application is
   available. Please click here to load it."

# Customising
In addition to the config/initializers/js_application_reloader.rb settings you
can also carry out the following customisations.

## Disable JsApplicationReloader for certain controllers
You can skip the before filter that JsApplicationReloader uses via

    skip_before_filter :handle_js_application_reloader_token_expiration

## Override what the server sends back to the client on token expiration

    # Override this in your ApplicationController or on a per controller basis.
    # The reload_required_http_status, application_name, redirect_url attributes
    # are available to you on the JsApplicationReloader object.
    def render_js_application_reloader_expiration
      message = "A new version of #{JsApplicationReloader.application_name} is available. " +
            "Please click <a href='#{JsApplicationReloader.redirect_url}'>here</a> to load it."

      respond_to do |format|
        format.html {
          render :text => message, :status => JsApplicationReloader.reload_required_http_status
        }
        format.json {
          render :json => {:message => message}, :status => JsApplicationReloader.reload_required_http_status
        }
      end
    end

## Override how the client handles the reloading of the application
You can put this at the bottom of your
config/initializers/js_application_reloader.rb (outside of the 'config' block).

    def JsApplicationReloader.handle_reloader_token_expiration_on_client
      <<-EOF
          JsApplicationReloader.handleTokenExpiration = function(xhr) {
            var contentType = xhr.getResponseHeader("content-type") || "";
            if (contentType.indexOf('html') > -1) {
              alert(xhr.responseText); // Changed to use an alert box
            }
            if (contentType.indexOf('json') > -1) {
              alert(xhr.responseJSON.message); // Changed to use an alert box
            }
            return false;
          };
      EOF
    end

## Future
There's lots to improve
* Usability: currently you are required to add a lot of code explicitly to your
  application. It would be good if this could be avoided. For example, instead
  of wiring up ajaxSend() calls perhaps we could do something with the
  XMLHttpRequest object (thanks for the idea Stefan!)
* Flexibility: cater for non-Rails applications and other JS frameworks
* Tests: this gem has been tested manually; it needs some spec love

So please fork and send a Pull Request.

## Contributing

1. Fork it ( https://github.com/theirishpenguin/js_application_reloader/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
