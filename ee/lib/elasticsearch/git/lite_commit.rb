# frozen_string_literal: true

module Elasticsearch
  module Git
    class LiteCommit
      extend Gitlab::Cache::RequestCache

      # Banzai accessors
      attr_accessor :redacted_description_html
      attr_accessor :redacted_title_html
      attr_accessor :redacted_full_title_html

      attr_accessor :id, :title, :description, :author_name, :author_email, :project, :rid, :authored_date,
                    :committed_date, :committer_email, :committer_name

      MIN_SHA_LENGTH = Gitlab::Git::Commit::MIN_SHA_LENGTH

      def initialize(repo, raw_commit_hash)
        #
        #         # {"id"=>"2ea1f3dec713d940208fb5ce4a38765ecb5d3f73",
        #         #  "message"=>"Add GitLab SVG\n",
        #         #  "parent_ids"=>["59e29889be61e6e0e5e223bfa9ac2721d31605b8"],
        #         #  "authored_date"=>"2015-11-13T07:39:43.000Z",
        #         #  "author_name"=>"Stan Hu",
        #         #  "author_email"=>"stanhu@gmail.com",
        #         #  "committed_date"=>"2015-11-13T07:39:43.000Z",
        #         #  "committer_name"=>"Stan Hu",
        #         #  "committer_email"=>"stanhu@gmail.com"}
        #

        # THIS IS WHAT A RAW HASH LOOKS LIKE
        # => {"type"=>"commit",
        #  "author"=>{"name"=>"Dmitriy Zaporozhets", "email"=>"dmitriy.zaporozhets@gmail.com", "time"=>"20130205T015210-0600"},
        #  "committer"=>{"name"=>"Dmitriy Zaporozhets", "email"=>"dmitriy.zaporozhets@gmail.com", "time"=>"20130205T015210-0600"},
        #  "rid"=>"2",
        #  "message"=>"More tests\n",
        #  "sha"=>"ea6ea902bea6857d2a0dbdf6d5492105a527d276"}

        @id = raw_commit_hash['sha']
        @title, @description = raw_commit_hash['message'].split("\n", 2)
        @project = repo
        @rid = repo.id
        @author_name = raw_commit_hash['author']['name']
        @author_email = raw_commit_hash['author']['email']
        @authored_date = Time.parse(raw_commit_hash['author']['time']).utc
        @committer_name = raw_commit_hash['committer']['name']
        @committer_email = raw_commit_hash['committer']['email']
        @committed_date = Time.parse(raw_commit_hash['committer']['time']).utc
      end

      def short_id
        id.to_s[0..MIN_SHA_LENGTH]
      end

      def has_signature?
        false
      end

      def lazy_author
        BatchLoader.for(author_email.downcase).batch do |emails, loader|
          users = User.by_any_email(emails).includes(:emails) # rubocop:disable CodeReuse/ActiveRecord

          emails.each do |email|
            user = users.find { |u| u.any_email?(email) }

            loader.call(email, user)
          end
        end
      end

      def author
        # We use __sync so that we get the actual objects back (including an actual
        # nil), instead of a wrapper, as returning a wrapped nil breaks a lot of
        # code.
        lazy_author.__sync
      end
      request_cache(:author) { author_email.downcase }

      def description?
        description.present?
      end

      def banzai_render_context(field)
        pipeline = field == :description ? :commit_description : :single_line
        context = { pipeline: pipeline, project: self.project }
        context[:author] = self.author if self.author

        context
      end
    end
  end
end
