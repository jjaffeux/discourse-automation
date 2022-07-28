# frozen_string_literal: true

require_relative '../discourse_automation_helper'

describe 'PMCreated' do
  before do
    SiteSetting.discourse_automation_enabled = true
    SiteSetting.personal_email_time_window_seconds = 0
  end

  fab!(:user) { Fabricate(:user) }
  fab!(:target_user) { Fabricate(:user) }
  let(:basic_topic_params) { { title: 'hello world topic', raw: 'my name is fred', archetype: Archetype.private_message, target_usernames: [target_user.username] } }
  fab!(:automation) { Fabricate(:automation, trigger: DiscourseAutomation::Triggerable::PM_CREATED) }

  context 'creating a PM' do
    before do
      automation.upsert_field!('restricted_user', 'user', { value: target_user.username }, target: 'trigger')
    end

    it 'fires the trigger' do
      output = JSON.parse(capture_stdout do
        PostCreator.create(user, basic_topic_params)
      end)

      expect(output['kind']).to eq('pm_created')
    end

    context 'trust_levels are restricted' do
      before do
        automation.upsert_field!('valid_trust_levels', 'trust-levels', { value: [2] }, target: 'trigger')
      end

      context 'trust level is allowed' do
        it 'fires the trigger' do
          output = JSON.parse(capture_stdout do
            user.trust_level = TrustLevel[2]
            user.save!
            PostCreator.create(user, basic_topic_params)
          end)

          expect(output['kind']).to eq('pm_created')
        end
      end

      context 'trust level is not allowed' do
        it 'doesn’t fire the trigger' do
          output = capture_stdout do
            user.trust_level = TrustLevel[1]
            user.save!
            PostCreator.create(user, basic_topic_params)
          end

          expect(output).to be_blank
        end
      end
    end

    context 'user is restricted' do
      context 'user is not allowed' do
        fab!(:user2) { Fabricate(:user) }

        it 'doesn’t fire the trigger' do
          output = capture_stdout do
            PostCreator.create(user, basic_topic_params.merge({ target_usernames: [user2.username] }))
          end

          expect(output).to be_blank
        end
      end
    end
  end
end