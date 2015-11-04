module Fastlane
  module Actions
    module SharedValues
       GITHUB_MILESTONE_CHANGELOG = :GITHUB_MILESTONE_CHANGELOG
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/KrauseFx/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class GenerateGithubMilestoneChangelogAction < Action
      def self.markdown_for_changelog_section (section, items)
        changelog = "\n#####{section}\n"
        items.each do |item|
          changelog << "* #{item["title"]}\n"
          changelog << " * Fixed by [#{item["user"]["login"]}](#{item["user"]["html_url"]}) in [##{item["number"]}](#{item["html_url"]}).\n"
        end
        return changelog
      end
      
      def self.replace(filepath, regexp, *args, &block)
        content = File.read(filepath).gsub(regexp, *args, &block)
        File.open(filepath, 'wb') { |file| file.write(content) }
      end
      
      def self.run(params)
        require 'net/http'
        require 'fileutils'
        
        url = "https://api.github.com/search/issues?q=repo%3A#{params[:github_organization]}%2F#{params[:github_repository]}+milestone%3A#{params[:milestone]}+state%3Aclosed"
        
        begin
          result = Net::HTTP.get(URI(url))
          begin
            result = JSON.parse(result) # try to parse and see if it's valid JSON data
          rescue
            # never mind, using standard text data instead
          end
        rescue => ex
          raise "Error fetching remote file: #{ex}"
        end
        
        items = result["items"]
        
        if items.count == 0
          raise "No closed issues found for #{params[:milestone]} in #{params[:github_organization]}/#{params[:github_repository]}".red
        end

        labels = [params[:added_label_name], params[:updated_label_name], params[:changed_label_name], params[:fixed_label_name], params[:removed_label_name]]
        sections = Array.new
        labels.each do |label_name|
          subitems = items.select {|item| item["labels"].any? {|label| label["name"].downcase == label_name.downcase}}
          if subitems.count > 0
            sections << {section: label_name, items: subitems}
            items = items - subitems
          end
        end

        if items.count > 0
          if sections.count > 0
            section_label = "Additional Changes"
          else
            section_label = "Changes"
          end
          sections << {section: section_label, items: items}
        end
        
        date = DateTime.now
        changelog = "\n##[#{params[:milestone]}](https://github.com/#{params[:github_organization]}/#{params[:github_repository]}/releases/tag/#{params[:milestone]}) (#{date.strftime("%m/%d/%Y")})"
        changelog << "\nReleased on #{date.strftime("%A, %B %d, %Y")}. All issues associated with this milestone can be found using this [filter](https://github.com/#{params[:github_organization]}/#{params[:github_repository]}/issues?q=milestone%3A#{params[:milestone]}+is%3Aclosed).\n"
        sections.each do |section|
          changelog << markdown_for_changelog_section(section[:section], section[:items])
        end
        Actions.lane_context[SharedValues::GITHUB_MILESTONE_CHANGELOG] = changelog
        
        if params[:changelog_file_path]
          replace(params[:changelog_file_path], /^#{params[:changelog_file_delimiter]}/mi) do |match| 
            "#{match} #{changelog}"
          end
          Helper.log.info "#{params[:changelog_file_path]} has been updated for #{params[:milestone]}".green
          
        end
        
        return changelog
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate a markdown formatted change log for a specific milestone in a Github repository"
      end

      def self.details

        "You can use this action to do cool things..."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :github_organization,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_ORGANIZATION", 
                                       description: "Github Organization for the repository",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :github_repository,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_REPOSITORY",
                                       description: "Github Repository containing the milestone",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :milestone,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_MILESTONE",
                                       description: "Milestone to generate changelog notes",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :added_label_name,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_ADDED_LABEL_NAME",
                                       description: "Github label name for all issues added during this milestone",
                                       is_string: true,
                                       default_value: "Added"),
          FastlaneCore::ConfigItem.new(key: :updated_label_name,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_UPDATED_LABEL_NAME",
                                       description: "Github label name for all issues updated during this milestone",
                                       is_string: true,
                                       default_value: "Updated"),
          FastlaneCore::ConfigItem.new(key: :changed_label_name,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_CHANGED_LABEL_NAME",
                                       description: "Github label name for all issues changed during this milestone",
                                       is_string: true,
                                       default_value: "Changed"),
          FastlaneCore::ConfigItem.new(key: :fixed_label_name,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_FIXED_LABEL_NAME",
                                       description: "Github label name for all issues fixed during this milestone",
                                       is_string: true,
                                       default_value: "Fixed"),
          FastlaneCore::ConfigItem.new(key: :removed_label_name,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_REMOVED_LABEL_NAME",
                                       description: "Github label name for all removed added during this milestone",
                                       is_string: true,
                                       default_value: "Removed"),
          FastlaneCore::ConfigItem.new(key: :changelog_file_path,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_FILE_PATH",
                                       description: "Path for the changelog",
                                       is_string: true,
                                       optional: true,
                                       verify_block: proc do |value|
                                         raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :changelog_file_delimiter,
                                       env_name: "FL_GENERATE_GITHUB_MILESTONE_CHANGELOG_FILE_DELIMITER",
                                       description: "The delimiter indicating where to insert the changelog for the milestone in the changelog file",
                                       is_string: true,
                                       default_value: "---")                                         
        ]
      end

      def self.output
        [
          ['GITHUB_MILESTONE_CHANGELOG', 'The formatted markdown changelog']
        ]
      end

      def self.return_value
        "Returns a markdown formatted change log to be added to CHANGELOG.md"
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
