# frozen_string_literal: true

require 'rails_helper'

Automation ||= DiscourseAutomation::Automation
Trigger ||= DiscourseAutomation::Trigger

describe Jobs::DiscourseAutomationTracker do
  before do
    freeze_time
  end

  describe 'pending automation' do
    let!(:automation) {
      automation = Automation.create!(
        name: 'Secret Santa',
        script: 'gift_exchange'
      )

      automation.create_trigger!(
        name: Trigger::POINT_IN_TIME,
      )

      automation.fields.create!(
        component: 'pm',
        name: 'giftee_assignment_message',
        metadata: {
          body: 'foo',
          title: 'bar'
        }
      )
      automation.fields.create!(
        component: 'group',
        name: 'gift_exchangers_group',
        metadata: { group_id: 1 }
      )

      automation
    }

    context 'pending automation is in past' do
      before do
        automation.trigger.update_with_params(metadata: { execute_at: 2.hours.ago })
      end

      it 'consumes the pending automation' do
        expect(automation.pending_automations.count).to eq(1)

        Jobs::DiscourseAutomationTracker.new.execute

        expect(automation.pending_automations.count).to eq(0)
      end
    end

    context 'pending automation is in future' do
      before do
        automation.trigger.update_with_params(metadata: { execute_at: 2.hours.from_now })
      end

      it 'doesn’t consume the pending automation' do
        expect(automation.pending_automations.count).to eq(1)

        Jobs::DiscourseAutomationTracker.new.execute

        expect(automation.pending_automations.count).to eq(1)
      end
    end
  end

  describe 'pending pms' do
    let!(:automation) {
      Automation.create!(
        name: 'On boarding',
        script: 'send_pms'
      )
    }

    context 'pending pm is in past' do
      before do
        automation.pending_pms.create!(
          title: 'Il pleure dans mon cœur Comme il pleut sur la ville;',
          raw: 'Quelle est cette langueur Qui pénètre mon cœur ?',
          execute_at: 2.hours.ago,
          sender: 'system'
        )
      end

      it 'consumes the pending pm' do
        expect(automation.pending_pms.count).to eq(1)

        Jobs::DiscourseAutomationTracker.new.execute

        expect(automation.pending_pms.count).to eq(0)
      end
    end

    context 'pending pm is in future' do
      before do
        automation.pending_pms.create!(
          title: 'Il pleure dans mon cœur Comme il pleut sur la ville;',
          raw: 'Quelle est cette langueur Qui pénètre mon cœur ?',
          execute_at: 2.hours.from_now,
          sender: 'system'
        )
      end

      it 'doesn’t consume the pending pm' do
        expect(automation.pending_pms.count).to eq(1)

        Jobs::DiscourseAutomationTracker.new.execute

        expect(automation.pending_pms.count).to eq(1)
      end
    end
  end
end
