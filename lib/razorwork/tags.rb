# frozen_string_literal: true

# Open main module.
module RazorWork
    # Create / Update / Delete tags.
    module Tags
        def self.check_tag_exists(name)
            begin
                all_tags = JSON.parse(RestClient.get($collection_urls['tags']))
            rescue => e
                RazorWork.log.error('Error while retrieving tag.')
                RazorWork.log.error(e.message)
                RazorWork.log.debug(e.backtrace)
                raise StandardError
            end
            RazorWork.log.debug("All tags: #{all_tags['items']}")

            all_tags['items'].each do |tag|
                RazorWork.log.info("Checking #{tag['name']}.")
                tag.each do |key, value|
                    if key == 'name' && value == name
                        RazorWork.log.info("Found existing tag named #{name}.")
                        return true
                    else
                        RazorWork.log.info('No match, try the next tag.')
                        next
                    end
                end
            end
            RazorWork.log.info("Tag named #{name} not found.")
            return false
        end

        def self.create_tag(name, config)
            begin
                RestClient.post(
                    $command_urls['create-tag'],
                    config.to_json,
                    content_type: :json, accept: :json
                )
            rescue => e
                RazorWork.log.error('Error while creating tag.')
                RazorWork.log.error(e.message)
                RazorWork.log.debug(e.backtrace)
                raise StandardError
            end
            RazorWork.log.info("Tag #{name} created.")
        end

        def self.check_fields_updatable(name, desired_config)
            # Current limitations of the razor API. Should ideally be
            # discovered dynamically.
            allowed_update_fields = ['rule']

            # Get current tag info, & remove superfluous keys.
            current_config = JSON.parse(
                RestClient.get("#{$collection_urls['tags']}/#{name}")
            )
            %w[id spec name].each { |i| current_config.delete(i) }

            # Note all fields which the desired config would update and
            # check against allowed list.
            desired_update_fields = []
            desired_config.each do |key, value|
                if current_config.key?(key) && current_config[key] != value
                    desired_update_fields.push(key)
                end
            end

            desired_update_fields.each do |field|
                return false unless allowed_update_fields.include?(field)
            end
        end

        def self.sync
            begin
                tag_files = Dir.glob('data/tags/*.yaml')
            rescue => e
                RazorWork.log.error('Error while loading tag files.')
                RazorWork.log.error(e.message)
                RazorWork.log.debug(e.backtrace)
                raise StandardError
            end
            RazorWork.log.info('tag files loaded.')

            # Load desired config and extract tag name.
            tag_files.each do |t|
                config = YAML.load_file(t)
                name = config['name']
                RazorWork.log.info("Loaded config for #{name}.")
                RazorWork.log.debug(config)

                # Either update existing tag or create new tag.
                if check_tag_exists(name)
                    RazorWork.log.info("Tag #{name} found.")

                    if check_fields_updatable(name, config)
                        RazorWork.log.info("Only updatable fields have changed;
                            safe to continue.")
                        update_fields(name, config)
                    else
                        RazorWork.log.error("One or more fields have changed for
                            which the razor API does not support in-place
                            updates.")
                        raise StandardError
                    end
                else
                    RazorWork.log.info("Tag #{name} not found; creating it.")
                    create_tag(name, config)
                end
            end
        end

        def self.update_fields(name, desired_config)
            # Get current config & drop unwanted keys.
            current_config = JSON.parse(
                RestClient.get("#{$collection_urls['tags']}/#{name}")
            )
            %w[id spec name].each { |i| current_config.delete(i) }

            # Call 'update_*' method on each field which differs from
            # current config.
            desired_config.each do |key, value|
                if current_config.key?(key) && current_config[key] != value
                    send("update_#{key}", name, value)
                end
            end
        end

        def self.update_rule(name, value, force=true)
            document = { "name": name, "rule": value, "force": force }
            RestClient.post(
                $command_urls['update-tag-rule'],
                document.to_json,
                content_type: :json, accept: :json
            )
        end
    end
end
