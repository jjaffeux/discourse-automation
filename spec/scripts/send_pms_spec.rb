# frozen_string_literal: true

require 'rails_helper'
require_relative '../fabricators/automation_fabricator'

describe 'SendPms' do
  fab!(:automation) { Fabricate(:automation, script: DiscourseAutomation::Scriptable::SEND_PMS, trigger: 'stalled_wiki') }

  before do
    automation.fields.create!(
      component: 'user',
      name: 'sender',
      metadata: { username: Discourse.system_user.username },
      target: 'script'
    )

    automation.fields.create!(
      component: 'pms',
      name: 'sendable_pms',
      metadata: {
        pms: [
          {
            title: 'A message from %%SENDER_USERNAME%%',
            raw: 'This is a message sent to @%%RECEIVER_USERNAME%%'
          }
        ]
      },
      target: 'script'
    )
  end

  context 'ran from stalled_wiki trigger' do
    fab!(:post_creator_1) { Fabricate(:user, admin: true) }
    fab!(:post_1) { Fabricate(:post, user: post_creator_1) }

    before do
      automation.upsert_field!('stalled_after', 'choices', { value: 'PT1H' }, target: 'trigger')
      automation.upsert_field!('retriggered_after', 'choices', { value: 'PT1H' }, target: 'trigger')

      post_1.revise(post_creator_1, { wiki: true }, { force_new_version: true, revised_at: 2.hours.ago })
    end

    it 'creates expected PM' do
      expect {
        Jobs::StalledWikiTracker.new.execute(nil)

        post = Post.last
        expect(post.topic.title).to eq("A message from #{Discourse.system_user.username}")
        expect(post.raw).to eq("This is a message sent to @#{post_creator_1.username}")
        expect(post.topic.topic_allowed_users.exists?(user_id: post_creator_1.id))
        expect(post.topic.topic_allowed_users.exists?(user_id: Discourse.system_user.id))
      }.to change { Post.count }.by(1)
    end
  end

  context 'ran from user_added_to_group trigger' do
    fab!(:user_1) { Fabricate(:user) }
    fab!(:tracked_group_1) { Fabricate(:group) }

    before do
      automation.update!(trigger: 'user_added_to_group')

      automation.fields.create!(
        component: 'group',
        name: 'joined_group',
        metadata: { group_id: tracked_group_1.id },
        target: 'trigger'
      )
    end

    it 'creates expected PM' do
      expect {
        tracked_group_1.add(user_1)

        post = Post.last
        expect(post.topic.title).to eq("A message from #{Discourse.system_user.username}")
        expect(post.raw).to eq("This is a message sent to @#{user_1.username}")
        expect(post.topic.topic_allowed_users.exists?(user_id: user_1.id))
        expect(post.topic.topic_allowed_users.exists?(user_id: Discourse.system_user.id))
      }.to change { Post.count }.by(1)
    end
  end
end
