# name: autocomplete-user-title
# about: shows user title in user autocomplete
# version: 1
# authors: Florian Humer
register_asset 'stylesheets/common/discourse-autocomplete-user-title.scss'

after_initialize do

  UsersController.class_eval do

    def search_users

      term = params[:term].to_s.strip
      topic_id = params[:topic_id]
      topic_id = topic_id.to_i if topic_id
      topic_allowed_users = params[:topic_allowed_users] || false

      group_names = params[:groups] || []
      group_names << params[:group] if params[:group]
      if group_names.present?
        @groups = Group.where(name: group_names)
      end

      results = UserSearch.new(term,
                               topic_id: topic_id,
                               topic_allowed_users: topic_allowed_users,
                               searching_user: current_user,
                               groups: @groups
                              ).search

      user_fields = [:username, :title, :upload_avatar_template]
      user_fields << :name if SiteSetting.enable_names?

      to_render = { users: results.as_json(only: user_fields, methods: [:avatar_template]) }

      groups =
        if current_user
          if params[:include_mentionable_groups] == 'true'
            Group.mentionable(current_user)
          elsif params[:include_messageable_groups] == 'true'
            Group.messageable(current_user)
          end
        end

      include_groups = params[:include_groups] == "true"

      # blank term is only handy for in-topic search of users after @
      # we do not want group results ever if term is blank
      include_groups = groups = nil if term.blank?

      if include_groups || groups
        groups = Group.search_groups(term, groups: groups)
        groups = groups.where(visibility_level: Group.visibility_levels[:public]) if include_groups
        groups = groups.order('groups.name asc')

        to_render[:groups] = groups.map do |m|
          { name: m.name, full_name: m.full_name }
        end
      end

      render json: to_render
    end

  end


  module HabidatDesign
    class Engine < ::Rails::Engine
      engine_name "habidat_design"
      isolate_namespace HabidatDesign
    end

    Rails.application.config.assets.paths.unshift File.expand_path('../assets', __FILE__)
  end


 
end
