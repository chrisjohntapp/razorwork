# frozen_string_literal: true

# Create / Update / Delete tags.
module Tags
    def self.check_tag_exists(name)
        all_tags = JSON.parse(RestClient.get($collection_urls['tags']))
        all_tags['items'].each do |tag|
            return false unless tag.key?('name') && tag['name'] == name
            return true
        end
    end

    def self.create_tag(config)
        RestClient.post($command_urls['create-tag'], config)
    end

    def self.check_fields_updatable(name, desired_config)
        # Current limitations of the razor API. Should ideally be discovered
        # dynamically.
        allowed_update_fields = ['rule']

        # Get current tag info, & remove superfluous keys.
        current_config = JSON.parse(
            RestClient.get("#{$collection_urls['tags']}/#{name}")
        )
        %w[id spec name].each { |i| current_config.delete(i) }

        # Note all fields which the desired config would update and check
        # against allowed list.
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
        tag_files = Dir.glob('../data/tags/*.yaml')

        # Load desired config and extract tag name.
        tag_files.each do |t|
            config = YAML.load_file(t).to_json
            name = config['name']

            # Either update existing tag (if possible) or create new tag.
            if check_tag_exists(name)
                if check_fields_updatable(name, config)
                    update_fields(name, config)
                else
                    # error: unsupported operation
                end
            else
                create_tag(config)
            end
        end
    end

    def self.update_fields(name, desired_config)
        # Get current config & drop unwanted keys.
        current_config = JSON.parse(
            RestClient.get("#{$collection_urls['tags']}/#{name}")
        )
        %w[id spec name].each { |i| current_config.delete(i) }

        # Call 'update_*' method on each field which differs from current
        # config.
        desired_config.each do |key, value|
            if current_config.key?(key) && current_config[key] != value
                send("update_#{key}", name, value)
            end
        end
    end

    def self.update_rule(name, value, force = true)
        document = { "name": name, "rule": value, "force": force }
        RestClient.post($command_urls['update-tag-rule'], document)
    end
end
