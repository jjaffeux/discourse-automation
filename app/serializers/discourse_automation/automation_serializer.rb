# frozen_string_literal: true

module DiscourseAutomation
  class AutomationSerializer < ApplicationSerializer
    attributes :id
    attributes :name
    attributes :enabled
    attributes :script
    attributes :trigger
    attributes :fields
    attributes :updated_at
    attributes :last_updated_by

    def last_updated_by
      BasicUserSerializer.new(User.find(object.last_updated_by_id), root: false).as_json
    end

    def script
      data = {
        id: object.script,
        version: scriptable.version,
        name: I18n.t("discourse_automation.scriptables.#{object.script}.title"),
        description: I18n.t("discourse_automation.scriptables.#{object.script}.description"),
        doc: I18n.t("discourse_automation.scriptables.#{object.script}.doc"),
        not_found: scriptable.not_found
      }

      data[:placeholders] = scriptable.placeholders if scriptable.placeholders

      data
    end

    def trigger
      data = {
        id: object.trigger,
        name: I18n.t("discourse_automation.scriptables.#{object.trigger}.title"),
        description: I18n.t("discourse_automation.scriptables.#{object.trigger}.description"),
        doc: I18n.t("discourse_automation.scriptables.#{object.trigger}.doc"),
        not_found: triggerable.not_found
      }

      data[:placeholders] = triggerable.placeholders if triggerable.placeholders

      data
    end

    def fields
      process_fields(triggerable, 'trigger') + process_fields(scriptable, 'script')
    end

    private

    def process_fields(target, target_name)
      fields = Array(target.fields).map do |script_field|
        field = object.fields.find_by(name: script_field[:name], component: script_field[:component])
        field || DiscourseAutomation::Field.new(name: script_field[:name], component: script_field[:component])
      end

      ActiveModel::ArraySerializer.new(
        fields,
        each_serializer: DiscourseAutomation::FieldSerializer,
        scope: { target: target, target_name: target_name }
      ).as_json || []
    end

    def scriptable
      DiscourseAutomation::Scriptable.new(object.script)
    end

    def triggerable
      DiscourseAutomation::Triggerable.new(object.trigger)
    end
  end
end
