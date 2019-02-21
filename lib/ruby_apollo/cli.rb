require 'thor'

module RubyApollo
  class CLI < Thor
    # ruby_apollo install
    
     desc "install", "Install RubyApollo"

     def install
      require "ruby_apollo/cli/install"
      Install.start
     end
  end
end
