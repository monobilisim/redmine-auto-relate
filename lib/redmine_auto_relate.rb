module RedmineAutoRelate
  MENTION_REGEX = /(?<![#\w\/])#(\d+)\b/.freeze

  module_function

  def extract_issue_ids(text)
    return [] if text.blank?

    text.scan(MENTION_REGEX).flatten.map(&:to_i).uniq
  end

  def relation_type
    type = Setting.plugin_redmine_auto_relate['relation_type'].to_s
    IssueRelation::TYPES.key?(type) ? type : IssueRelation::TYPE_RELATES
  end

  def scan_description?
    Setting.plugin_redmine_auto_relate['scan_description'].to_s == '1'
  end

  def scan_notes?
    Setting.plugin_redmine_auto_relate['scan_notes'].to_s == '1'
  end

  def link_issue(from_issue, to_id, user)
    return if from_issue.nil? || to_id.blank?
    return if from_issue.id == to_id.to_i

    target = Issue.find_by(id: to_id)
    return if target.nil?
    return if user && !target.visible?(user)

    return if IssueRelation.where(
      issue_from_id: from_issue.id, issue_to_id: target.id
    ).or(
      IssueRelation.where(issue_from_id: target.id, issue_to_id: from_issue.id)
    ).exists?

    relation = IssueRelation.new(
      issue_from: from_issue,
      issue_to: target,
      relation_type: relation_type
    )

    unless relation.save
      Rails.logger.info(
        "[redmine_auto_relate] #{from_issue.id} -> #{target.id} ilişkisi kurulamadı: " \
        "#{relation.errors.full_messages.join(', ')}"
      )
    end
  rescue => e
    Rails.logger.error("[redmine_auto_relate] Hata: #{e.class}: #{e.message}")
  end

  def link_all(from_issue, text, user)
    extract_issue_ids(text).each do |to_id|
      link_issue(from_issue, to_id, user)
    end
  end
end

require_relative 'redmine_auto_relate/issue_patch'
require_relative 'redmine_auto_relate/journal_patch'
