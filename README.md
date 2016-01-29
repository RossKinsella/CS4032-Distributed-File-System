All non-gem/std lib work is my own.

Steps
* clone the project
* sh start.sh (I'm using ruby 2.1.2)
* If it complains about ports, you can change them in common/utils.rb
* This will run the tests in Tests/integration_tests.rb
* Have a look at the logs, every message is recorded

I did Auth, Directory and Locking.
Use flow is as follows;
 1. ProxyFile.login username, password
    -> This will just set the username and password
 2. file = ProxyFile.open 'path'
    -> This authenticate the user, find which file server (or designate one if it does not already exist) the file is on and return the directory details.
       -> If a file server is being designated by the directory for a new file, the directory will message the locking server to inform it of the new file/
    -> Establish a connection with the file server storing this file
    -> return a ProxyFile instance
 3. file.read
    -> This will download the file from the file server and return a string of the contents (works for any size file)
 4. file.write
    -> Provided the lock has been acquired, this will upload the file to the relevant file server
 5. file.close
    -> sends a disconnect message to the fileserver, ending the connection and freeing its resources up.
    -> released the lock, messaging the locking service
 5. file.attempt_lock
    -> sends a lock request along with the associated file_id to the locking service
    -> returns true if the lock was granted, otherwise false
 6. file.unlock
    -> if the ProxyFile isntance holds the lock, this will message the locking service, releasing the lock.


All messages are encrypted using the Kerborose(3 key) method.
All services are multi-threaded and can keep taking new connections until it falls over due to spam mem-swaps