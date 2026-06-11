module RedmineAutoRelate
  module JournalPatch
    def self.prepended(base)
      base.class_eval do
        after_create_commit :auto_relate_from_notes
      end
    end

    private

    def auto_relate_from_notes
      return unless RedmineAutoRelate.scan_notes?
      return if notes.blank?
      return unless journalized.is_a?(Issue)

      RedmineAutoRelate.link_all(journalized, notes, user || User.current)
    end
  end
end
