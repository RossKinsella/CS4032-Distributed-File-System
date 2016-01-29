require_relative './lock_service.rb'
require_relative '../common/utils.rb'
require_relative './lock_service_router.rb'

class LockServer

  NAME = "Lock Service"
  KEY = Digest::SHA1.hexdigest "lemonade"

  def initialize

    ip = SERVICE_CONNECTION_DETAILS['lock']['ip']
    port = SERVICE_CONNECTION_DETAILS['lock']['port']

    service = LockService.new NAME, KEY
    server = TCPServer.new(
      ip,
      port)

    LOGGER.log "\n ###############\n Starting Lock Server: #{NAME} \n ###############"
    LOGGER.log "Listening on #{ip}:#{port}"

    loop do
      Thread.start(server.accept) do |user_socket|
        begin
          session = ServiceSession.new user_socket, service
          LOGGER.log '//////////// Lock Server: Accepted connection ////////////////'
          loop do
            request = session.get_request()
            if request == ''
              LOGGER.log 'Empty request received. Disconnecting user.'
              session.disconnect()
            else
              begin
                LockServiceRouter.route(service, request, session)
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
