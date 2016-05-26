import Foundation

class HTTPServer: NSObject {
    var listeningHandle : NSFileHandle? = nil
    
    func start() {
        let swiftSocket = SwiftSocket()
        let nativeSocket = swiftSocket.getSocket(port: UInt16(Configuration.port))
        prepareListeningHandle(nativeSocket: nativeSocket!)
        if (listeningHandle != nil) {
            print ("Server started at localhost:\(Configuration.port)")
            listeningHandle!.acceptConnectionInBackgroundAndNotify()
        } else {
            print("LISTENING HANDLE NOT PREPARED")
        }
        
    }
    
    func stop() {
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    
    func prepareListeningHandle(nativeSocket: CFSocketNativeHandle) {
        listeningHandle = NSFileHandle(fileDescriptor: nativeSocket, closeOnDealloc: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receiveIncomingAcceptedConnectionNotification), name: NSFileHandleConnectionAcceptedNotification, object: nil)
    }
    
    func receiveIncomingAcceptedConnectionNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String : AnyObject] {
            let incomingFileHandle = userInfo[NSFileHandleNotificationFileHandleItem] as? NSFileHandle
            if let data = incomingFileHandle?.availableData {
                let incomingRequestString = String.init(data: data, encoding: NSUTF8StringEncoding)
                if (incomingRequestString!.characters.count > 0) {
                    let request : Request = Request(requestString: incomingRequestString!)
                    let responseHandler = HTTPResponseHandler()
                    let response = responseHandler.getResponse(request: request)
                    let myData = NSData(bytes: response, length: response.count)
                    incomingFileHandle!.write(myData)
                }
            }
        }
        listeningHandle!.acceptConnectionInBackgroundAndNotify()
    }
    
    func getByteArrayFromString(string: String) -> UnsafePointer<Int8> {
        var myArray = [Int8]()
        let myCString = string.cString(using: NSUTF8StringEncoding)
        for char in myCString! {
            myArray.append(char)
        }
        return UnsafePointer(myArray)
    }
}