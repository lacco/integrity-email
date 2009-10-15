require "integrity"
require "sinatra/ditties/mailer"

module Integrity
  class Notifier
    class Email < Notifier::Base
      attr_reader :to, :from
      
      def self.notify_of_build(build, config)
        # Only send email when build is failed
        build.failed? ? super : true
      end

      def self.to_haml
        File.read(File.dirname(__FILE__) + "/config.haml")
      end

      def initialize(commit, config={})
        @to     = config.delete("to")
        @from   = config.delete("from")
        super(commit, config)
        configure_mailer
      end

      def deliver!
        email.deliver!
      end

      def email
        @email ||= Sinatra::Mailer::Email.new(
          :to       => to,
          :from     => from,
          :text     => body,
          :subject  => subject
        )
      end

      def subject
        "[Integrity] #{commit.project.name}: #{short_message}"
      end

      alias_method :body, :full_message

      private
        def configure_mailer
          return configure_sendmail unless @config["sendmail"].blank?
          configure_smtp
        end

        def configure_smtp
          user = @config["user"] || ""
          pass = @config["pass"] || ""
          user = nil if user.empty?
          pass = nil if pass.empty?

          Sinatra::Mailer.delivery_method = "net_smtp"

          Sinatra::Mailer.config = {
            :host => @config["host"],
            :port => @config["port"],
            :user => user,
            :pass => pass,
            :auth => @config["auth"],
            :domain => @config["domain"]
          }
        end

        def configure_sendmail
          Sinatra::Mailer.delivery_method = :sendmail
          Sinatra::Mailer.config = {:sendmail_path => @config['sendmail']}
        end
    end

    register Email
  end
end
