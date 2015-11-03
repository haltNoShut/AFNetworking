module Fastlane
  module Actions
    module SharedValues
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/KrauseFx/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class UpdatePodspecVersionAction < Action
      def self.run(params)
          text = File.read(params[:podspec_file_path])
          new_contents = text.gsub(/s.version  *= '[0-9].*'/, "s.version = '#{params[:version]}'")
          File.open(params[:podspec_file_path], "w") {|file| file.puts new_contents }
          
          sh("pod spec lint --quick")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Update the podspec version."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_PODSPEC_VERSION",
                                       description: "The version to update the podspec",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :podspec_file_path,
                                       env_name: "FL_PODSPEC_PATH",
                                       description: "The path to the podspec file",
                                       is_string: true)
        ]
      end

      def self.authors
        ["kcharwood"]
      end

      def self.is_supported?(platform)
        return true
      end
    end
  end
end
