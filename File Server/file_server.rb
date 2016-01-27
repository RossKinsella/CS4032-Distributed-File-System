require_relative './file_service.rb'
require_relative '../utils.rb'
require_relative './router.rb'
require_relative './session.rb'

class FileServer

  def initialize
    pool = ThreadPool.new(10)
    file_service = FileService.new Digest::SHA1.hexdigest '__Thor__password__'
    server = TCPServer.new(
      SERVICE_CONNECTION_DETAILS['file']['ip'],
      SERVICE_CONNECTION_DETAILS['file']['port'])

    LOGGER.log "###############\n Starting File Server \n ###############"
    LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['file']['ip']}:#{SERVICE_CONNECTION_DETAILS['file']['port']}"

    loop do
      pool.schedule do
        begin
          user_socket = server.accept_nonblock
          session = Session.new user_socket, file_service

          LOGGER.log '//////////// File Server: Accepted connection ////////////////'

          while session.is_connected
            begin
              request = session.get_request()
              if request == ''
                LOGGER.log 'Empty request received. Disconnecting user.'
                session.disconnect()
              else
                begin
                  Router.route(file_service, request, session)
                rescue => e
                  LOGGER.log e
                  LOGGER.log e.backtrace.join "\n"
                end
              end

            rescue
             # Dont starve the other threads you dick...
             sleep(0.1)
            end
          end

          LOGGER.log 'Connection to client has been lost'
          session.disconnect()

        rescue
          # DO NOTHING
        end
      end
    end

    at_exit { pool.shutdown }
  end

end
