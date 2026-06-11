require 'redmine'

require File.expand_path('lib/redmine_auto_relate', __dir__)

Redmine::Plugin.register :redmine_auto_relate do
  name        'Redmine Auto Relate'
  author      'Ali Erdem Cerrah'
  description 'When a job number appears in a job description or note in the format #NNN, it automatically adds that job to the “related jobs” list for the current job.'
  version     '0.1.0'
  requires_redmine version_or_higher: '5.0.0'

  settings(
    default: {
      'relation_type' => IssueRelation::TYPE_RELATES,
      'scan_description' => '1',
      'scan_notes' => '1'
    },
    partial: 'settings/redmine_auto_relate'
  )
end

apply_patches = proc do
  unless Issue.ancestors.include?(RedmineAutoRelate::IssuePatch)
    Issue.prepend(RedmineAutoRelate::IssuePatch)
  end

  unless Journal.ancestors.include?(RedmineAutoRelate::JournalPatch)
    Journal.prepend(RedmineAutoRelate::JournalPatch)
  end
end

if Rails.env.development?
  ActiveSupport::Reloader.to_prepare(&apply_patches)
else
  apply_patches.call
end
