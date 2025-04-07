def require_auth
  auth_header = request.env["HTTP_AUTHORIZATION"]
  token = auth_header&.split(' ')&.last
  payload = decode_access_token(token)
  halt 401, { error: "No autenticado o token expirado" }.to_json unless payload
end

def generate_access_token(user)
  payload = { user: user, exp: Time.now.to_i + ACCESS_TOKEN_EXPIRATION }
  JWT.encode(payload, SECRET_KEY, 'HS256')
end


# Decodificar Access Token
def decode_access_token(token)
  JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' }).first
rescue JWT::DecodeError
  nil
end

def generate_refresh_token(user)
  token = SecureRandom.hex(32)
  REFRESH_TOKENS[token] = { user: user, exp: Time.now.to_i + REFRESH_TOKEN_EXPIRATION }
  token
end

def validate_refresh_token(token)
  data = REFRESH_TOKENS[token]
  return nil unless data
  return nil if data[:exp] < Time.now.to_i # expirado
  data[:user]
end

def is_authenticate?
  auth_header = request.env["HTTP_AUTHORIZATION"]
  return false unless auth_header

  if LOGGED_USERS[auth_header]
    true
  else
    false
  end
end