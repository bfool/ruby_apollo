require "thor/group"

module RubyApollo
  class CLI < Thor
    class Install < Thor::Group
      include Thor::Actions

      class_option "apollo_info_path",
        aliases: ["-p"],
        default: "config/apollo_info.txt",
        desc: "Specify a apollo info file path"

      class_option "apollo_path",
        aliases: ["-p"],
        default: "config/initializers/apollo.rb",
        desc: "Specify a apollo file path"
      
      def self.source_root
        File.expand_path("../install", __FILE__)
      end

      def create_configuration
        copy_file("apollo_info.txt", options[:apollo_info_path])
        copy_file("apollo.rb", options[:apollo_path])
      end

#       def ignore_configuration
#         if File.exists?(".gitignore")
#           append_to_file(".gitignore", <<-EOF)
# # Ignore application configuration
# /#{options[:path]}
# EOF
#         end
#       end
    end
  end
end
