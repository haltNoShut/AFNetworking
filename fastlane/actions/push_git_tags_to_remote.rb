module Fastlane
  module Actions
    class PushGitTagsToRemoteAction < Action
      def self.run(params)
          command = [
            'git',
            'push']
            
          if params[:remote]
            command >> params[:remote]
          end
          command >> '--tags'

          result = Actions.sh(command.join(' '))
          Helper.log.info 'Tags pushed to remote'.green
          result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def self.description
          "Push local tags to the remote - this will only push tags"
        end

        def self.available_options
          [
          FastlaneCore::ConfigItem.new(key: :remote,
                                       env_name: "FL_PUSH_GIT_TAGS_REMOTE",
                                       description: "The remote to push tags too",
                                       is_string:true,
                                       optional:true)
          ]
        end

        def self.author
          ['vittoriom']
        end

        def self.is_supported?(platform)
          true
        end
      end
    end
  end

        