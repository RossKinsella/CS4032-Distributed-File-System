require_relative '../common/utils.rb'
require_relative './directory_service.rb'
require_relative './directory_service_router.rb'

class DirectoryServer

  NAME = 'Odin'
  KEY = Digest::SHA1.hexdigest 'LEMONS'

  def initialize

    pool = ThreadPool.new(10)
    service = DirectoryService.new NAME, KEY
    server = TCPServer.new(
      SERVICE_CONNECTION_DETAILS['directory']['ip'],
      SERVICE_CONNECTION_DETAILS['directory']['port'])
    LOGGER.log "\n ############### \n Starting Directory Server \n ###############"
    LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['directory']['ip']}:#{SERVICE_CONNECTION_DETAILS['directory']['port']}"

    loop do
      pool.schedule do
        begin
          user_socket = server.accept_nonblock
          session = ServiceSession.new user_socket, service

          LOGGER.log '//////////// Directory Server: Accepted connection ////////////////'

          while session.is_connected
            begin
              request = session.get_request()
              if request == ''
                LOGGER.log 'Empty request received. Disconnecting user.'
                session.disconnect()
              else
                begin
                  DirectoryServiceRouter.route service, session, request
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
