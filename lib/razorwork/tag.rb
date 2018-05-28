# frozen_string_literal: true

# Open main module.
module RazorWork
    # Manage tags.
    module Tag
        # Read-only actions on the Razor API.
        module Check
            def self.find_match(tag_name, all_tags)
                all_tags['items'].each do |tag|
                    tag.each do |key, value|
                        if key == 'name' && value == tag_name
                            RazorWork.log.info("Found #{tag_name}.")
                            return true
                        else
                            next
                        end
                    end
                end
                RazorWork.log.info("Tag #{tag_name} not found.")
                return false
            end

            def self.retrieve_tags
                begin
                    all_tags = JSON.parse(
                        RestClient.get($collection_urls['tags'])
                    )
                rescue StandardError => e
                    RazorWork.log.error(e.message)
                    RazorWork.log.debug(e.backtrace)
                    raise RazorError::APIError
                end
                RazorWork.log.debug("Retrieved tags: #{all_tags}")
                return all_tags
            end

            def self.retrieve_current_config(tag_name)
                begin
                    current_config = JSON.parse(
                        RestClient.get(
                            "#{$collection_urls['tags']}/#{tag_name}"
                        )
                    )
                rescue StandardError => e
                    RazorWork.log.error(e.message)
                    RazorWork.log.debug(e.backtrace)
                    raise RazorError::APIError
                end
                RazorWork.log.debug("Retrieved config: #{current_config}")

                # Remove superfluous keys.
                %w[id spec name].each { |i| current_config.delete(i) }
                return current_config
            end

            def self.check_fields_updatable(current_config, desired_config)
                # Current limitations of the razor API.
                allowed_update_fields = ['rule']

                desired_update_fields = []
                desired_config.each do |key, value|
                    if current_config.key?(key) && current_config[key] != value
                        desired_update_fields.push(key)
                    end
                end

                desired_update_fields.each do |field|
                    allowed_update_fields.include?(field) ? true : false
                end
            end
        end

        # Create.
        module Create
            def self.create_tag(name, config)
                begin
                    RestClient.post(
                        $command_urls['create-tag'],
                        config.to_json,
                        content_type: :json, accept: :json
                    )
                rescue StandardError => e
                    RazorWork.log.error('Error while creating tag.')
                    RazorWork.log.error(e.message)
                    RazorWork.log.debug(e.backtrace)
                    raise
                end
                RazorWork.log.info("Tag #{name} created.")
            end
        end

        # Update existing records.
        module Update
            def self.update_rule(tag_name, rule, force=true)
                document = { "name": tag_name, "rule": rule, "force": force }
                begin
                    RestClient.post(
                        $command_urls['update-tag-rule'],
                        document.to_json,
                        content_type: :json, accept: :json
                    )
                rescue StandardError => e
                    RazorWork.log.error(e.message)
                    RazorWork.log.debug(e.backtrace)
                    raise RazorError::APIError
                end
                RazorWork.log.info("Updated rule for #{tag_name} to #{rule}")
            end

            def self.update_fields(tag_name, desired_config)
                current_config = Check.retrieve_current_config(tag_name)

                # Call 'update_*' method on each field which differs from
                # current config.
                desired_config.each do |key, value|
                    if current_config.key?(key) && current_config[key] != value
                        send("update_#{key}", tag_name, value)
                    end
                end
            end
        end

        # Misc methods.
        module Main
            def self.find_files(tag_dir='data/tag')
                tag_files = Dir.glob("#{tag_dir}/*.yaml")
                if tag_files.empty?
                    RazorWork.log.info('No tag config files were found.')
                else
                    RazorWork.log.info('tag files loaded.')
                    RazorWork.log.debug(tag_files)
                end
                return tag_files
            end

            # Main Tag method.
            def self.sync
                find_files.each do |file|
                    desired_config = YAML.load_file(file)
                    tag_name = desired_config['name']
                    RazorWork.log.debug(
                        "Loaded config from #{file}: #{desired_config}"
                    )

                    current_tags = Check.retrieve_tags
                    if Check.find_match(tag_name, current_tags)
                        RazorWork.log.info("Tag #{tag_name} found.")

                        current_config = Check.retrieve_current_config(tag_name)

                        if Check.check_fields_updatable(
                            current_config, desired_config
                        )
                            RazorWork.log.info(
                                "All changed fields for #{tag_name} are
                                updatable."
                            )
                            Update.update_fields(tag_name, desired_config)
                        else
                            RazorWork.log.error("You are trying to change one or
                                more fields of #{tag_name} for which the Razor
                                API does not support in-place updates.")
                            raise RazorError.APILimitation
                        end
                    else
                        RazorWork.log.info("Tag #{tag_name} not found.")
                        Create.create_tag(tag_name, desired_config)
                    end
                end
            end
        end
    end
end
