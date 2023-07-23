# frozen_string_literal: true

require "pathname"
require "net/http"
require "uri"

require "faye/websocket"
require "sinatra"
require 'sinatra/cross_origin'

require "./lib/mail_catcher/bus"
require "./lib/mail_catcher/mail"

Faye::WebSocket.load_adapter("thin")

# Faye's adapter isn't smart enough to close websockets when thin is stopped,
# so we teach it to do so.
module Thin
  module Backends
    class Base
      alias thin_stop stop

      def stop
        thin_stop
        @connections.each_value do |connection|
          connection.socket_stream&.close_connection_after_writing
        end
      end
    end
  end
end

module Sinatra
  class Request
    include Faye::WebSocket::Adapter
  end
end

module MailCatcher
  module Web
    class Application < Sinatra::Base
      set :environment, MailCatcher.env
      set :prefix, MailCatcher.options[:http_path]
      set :root, File.expand_path("#{__FILE__}/../../../..")
      set :allow_origin, "*"
      set :allow_methods, "GET,DELETE,PATCH,OPTIONS"
      set :allow_headers, "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept, if-modified-since"
      set :expose_headers, "location,link"

      configure do
        enable :cross_origin
      end

      options "*" do
        response.headers["Access-Control-Allow-Methods"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"
        200
      end

      before do
        response.headers['Access-Control-Allow-Origin'] = '*'
      end

      auth_user = ENV.fetch("MAILCATCHER_AUTH_USER", nil)
      auth_password = ENV.fetch("MAILCATCHER_AUTH_PASSWORD", nil)

      delete "/" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        if MailCatcher.quittable?
          MailCatcher.quit!
          status 204
        else
          status 403
        end
      end

      get "/messages" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        if request.websocket?
          bus_subscription = nil

          ws = Faye::WebSocket.new(request.env)
          ws.on(:open) do |_|
            bus_subscription = MailCatcher::Bus.subscribe do |message|
              ws.send(JSON.generate(message))
            rescue StandardError => e
              MailCatcher.log_exception("Error sending message through websocket", message, e)
            end
          end

          ws.on(:close) do |_|
            MailCatcher::Bus.unsubscribe(bus_subscription) if bus_subscription
          end

          ws.rack_response
        else
          content_type :json
          JSON.generate(Mail.messages)
        end
      end

      delete "/messages" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        Mail.delete!
        status 204
      end

      get "/messages/:id.json" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (message = Mail.message(id))
          content_type :json
          JSON.generate(message.merge({
                                        "formats" => [
                                          "source",
                                          ("html" if Mail.message_has_html? id),
                                          ("plain" if Mail.message_has_plain? id)
                                        ].compact,
                                        "attachments" => Mail.message_attachments(id)
                                      }))
        else
          not_found
        end
      end

      get "/messages/:id.html" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (part = Mail.message_part_html(id))
          content_type :html, charset: (part["charset"] || "utf8")

          body = part["body"]

          # Rewrite body to link to embedded attachments served by cid
          body.gsub!(/cid:([^'"> ]+)/, "#{id}/parts/\\1")

          body
        else
          not_found
        end
      end

      get "/messages/:id.plain" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (part = Mail.message_part_plain(id))
          content_type part["type"], charset: (part["charset"] || "utf8")
          part["body"]
        else
          not_found
        end
      end

      get "/messages/:id.source" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (message_source = Mail.message_source(id))
          content_type "text/plain"
          message_source
        else
          not_found
        end
      end

      get "/messages/:id.eml" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (message_source = Mail.message_source(id))
          content_type "message/rfc822"
          message_source
        else
          not_found
        end
      end

      get "/messages/:id/parts/:cid" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if (part = Mail.message_part_cid(id, params[:cid]))
          content_type part["type"], charset: (part["charset"] || "utf8")
          attachment part["filename"] if part["is_attachment"] == 1
          body part["body"].to_s
        else
          not_found
        end
      end

      delete "/messages/:id" do
        response.headers['Access-Control-Allow-Origin'] = '*'

        id = params[:id].to_i
        if Mail.message(id)
          Mail.delete_message!(id)
          status 204
        else
          not_found
        end
      end
    end
  end
end
