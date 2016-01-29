require_relative '../common/utils.rb'
require_relative './directory_service.rb'
require_relative './directory_service_router.rb'

class DirectoryServer

  NAME = 'Directory Service'
  KEY = Digest::SHA1.hexdigest 'LEMONS'

  def initialize
    service = DirectoryService.new NAME, KEY
    server = TCPServer.new(
      SERVICE_CONNECTION_DETAILS['directory']['ip'],
      SERVICE_CONNECTION_DETAILS['directory']['port'])
    LOGGER.log "\n ############### \n Starting Directory Server \n ###############"
    LOGGER.log "Listening on #{SERVICE_CONNECTION_DETAILS['directory']['ip']}:#{SERVICE_CONNECTION_DETAILS['directory']['port']}"

    loop do
      Thread.start(server.accept) do |user_socket|
        begin
          session = ServiceSession.new user_socket, service
          LOGGER.log '//////////// Directory Server: Accepted connection ////////////////'
          loop do
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
          end
        rescue => e
          LOGGER.log e
        end
      end
    end
  end

end
