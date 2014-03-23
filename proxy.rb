require 'goliath'

class Proxy < Goliath::API
  def response(env)
    [200, {}, "Hello World"]
  end
end

