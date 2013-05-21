require 'securerandom'

# Returns a salted hash digest of the string.
def digest(string)
  salt = SecureRandom.base64
  Digest::SHA1.hexdigest(salt + string)
end

# Escapes backslashes.
# Interpolated backslashes need extra escaping.
# We only escape '\\' by itself, i.e., a backslash followed by spaces 
# or the end of line.
def escape_backslashes(string)
  string.gsub(/\\(\s+|$)/) { '\\\\' + $1.to_s }
end
