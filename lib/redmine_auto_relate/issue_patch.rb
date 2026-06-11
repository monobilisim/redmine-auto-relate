module RedmineAutoRelate
  module IssuePatch
    def self.prepended(base)
      base.class_eval do
        after_save :auto_relate_from_description
      end
    end

    private

    def auto_relate_from_description
      return unless RedmineAutoRelate.scan_description?
      return unless saved_change_to_attribute?(:description)
      return if description.blank?

      RedmineAutoRelate.link_all(self, description, author || User.current)
    end
  end
end
