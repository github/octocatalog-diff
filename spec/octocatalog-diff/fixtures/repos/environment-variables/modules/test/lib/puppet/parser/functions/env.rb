module Puppet::Parser::Functions
  newfunction(:env, type: :rvalue) { |args| ENV[args[0]] }
end
