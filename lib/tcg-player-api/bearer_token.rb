class TCGPlayerAPI::BearerToken
  attr_accessor :expires_in, :token, :expiration, :issued

  def initialize(params = {})
    self.expires_in = params['expires_in']
    self.token = params['access_token']
    self.issued = DateTime.parse(params['.issued'])
    self.expiration = DateTime.parse(params['.expires'])
  end

  ##
  # @return true if the bearer token is within five minutes of expiring
  def expired?
    return expiration.nil? || (DateTime.now >= expiration)
  end

  def to_s
    ap self, indent: -2
  end
end
