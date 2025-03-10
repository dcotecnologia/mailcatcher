# frozen_string_literal: true

require "eventmachine"

require "./lib/mail_catcher/mail"

module MailCatcher
  class Smtp < EventMachine::Protocols::SmtpServer
    # We override EM's mail from processing to allow multiple mail-from commands
    # per [RFC 2821](https://tools.ietf.org/html/rfc2821#section-4.1.1.2)
    def process_mail_from(sender)
      if @state.include? :mail_from
        @state -= %i[mail_from rcpt data]

        receive_reset
      end

      super
    end

    def current_message
      @current_message ||= {}
    end

    def receive_reset
      @current_message = nil

      true
    end

    def receive_sender(sender)
      # EventMachine SMTP advertises size extensions [https://tools.ietf.org/html/rfc1870]
      # so strip potential " SIZE=..." suffixes from senders
      sender = ::Regexp.last_match.pre_match if sender =~ / SIZE=\d+\z/

      current_message[:sender] = sender

      true
    end

    def receive_recipient(recipient)
      current_message[:recipients] ||= []
      current_message[:recipients] << recipient

      true
    end

    def receive_data_chunk(lines)
      current_message[:source] ||= +""

      lines.each do |line|
        current_message[:source] << line << "\r\n"
      end

      true
    end

    def receive_message
      MailCatcher::Mail.add_message current_message
      MailCatcher::Mail.delete_older_messages!
      puts "==> SMTP: Received message from '#{current_message[:sender]}' (#{current_message[:source].length} bytes)"
      true
    rescue StandardError => e
      MailCatcher.log_exception("Error receiving message", @current_message, e)
      false
    ensure
      @current_message = nil
    end
  end
end
