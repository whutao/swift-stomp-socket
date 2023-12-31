//
//  Created by Roman Nabiullin
//
//  Copyright (c) 2023 - Present
//
//  All Rights Reserved.
//

import Foundation

// MARK: - Model

extension STOMPSocket {
	
	/// Exposed event kinds that are generated by the web-socket.
	public enum Event {
		
		// MARK: Case
		
		/// Connection request has just been sent to a server.
		case isConnecting
		
		/// Both STOMP sub-protocol and web-socket are connected and ready to send messages.
		case didConnect
		
		/// Both STOMP sub-protocol and web-socket are disconnected. It will not be auto-reconnected.
		/// Instead, the web-socket should be explicitly connected again.
		case didDisconnect
		
		/// Some decoded payload received from a subscribed destination.
		case didReceivePayload(Decodable, from: String)
		
		/// Error recevied via websocket.
		case didReceiveError(description: String)
		
	}
	
}
