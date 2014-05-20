require 'dotenv'
Dotenv.load

require 'bundler/setup'
require 'action_view'
Bundler.require(:default)
require 'action_dispatch'
require 'active_support'

class Proxy < Goliath::API
  include Goliath::Rack::Templates

  def response(env)
    host = ENV['RACK_ENV'] == 'production'  ?
      env['SERVER_NAME'] : 'test.kissr.com'


    if host.match(/staging.kissr.com$/)
      host.sub!('staging.kissr.com','kissr.com')
      bucket = 'kissr-staging'
    else
      bucket = ENV['KISSR_BUCKET']
    end

    bucket = aws.directories.new(key: ENV['KISSR_BUCKET'])

    request = env['REQUEST_PATH']

    if request[-1, 1] == '/'
      request += 'index.html'
    end

    file = bucket.files.get("#{host}#{request}")

    if file.present?
      content_type = mime_type(File.extname(request)[1..-1])

      [
        200,
        {"Content-Type" => content_type },
        file.body
      ]
    else
      [
        404,
        {},
        haml(:not_found)
      ]
    end
  end

  def mime_type(extention)
    extentions = {'htm' => "text/html"}
    if extentions[extention]
      extentions[extention]
    else
      Mime::Type.lookup_by_extension(extention).to_s
    end
  end

  def aws
    @aws ||= Fog::Storage.new(
      provider: 'AWS',
      aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end
end

