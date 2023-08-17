//
//  Created by Roman Nabiullin
//
//  Copyright (c) 2023 - Present
//
//  All Rights Reserved.
//

import Foundation
import SwiftStomp

// MARK: - Socket

/// Proxy service for working with STOMP web-sockets.
///
/// Utilizes `SwiftStomp` library and uses `SwiftStomp.SwiftStompDelegate` as a strong property.
/// `StompSocket` instances will not be released until the delegate is unset.
/// Delegate property is **not unset until** the web-socket is disconnected.
public final class STOMPSocket {
	
	// MARK: Exposed properties
	
	/// Returns `true` iff web-socket is connected via STOMP sub-protocol.
	public var isConnectedViaSTOMP: Bool {
		return (stompClient.connectionStatus == .fullyConnected)
	}
	
	// MARK: Private properties
	
	public var isConnecting: Bool {
		return (stompClient.connectionStatus == .connecting)
	}
	
	private var eventHandler: (STOMPSocket, Event) -> Void
	
	private let stompClient: SwiftStomp
	
	private let timeIntervalForTimeout: TimeInterval
	
	private let timeIntervalForPing: TimeInterval
	
	private let receivedMessageTypes: [Decodable.Type]
	
	private let receivedMessageJSONDecoder: JSONDecoder
	
	// MARK: Init
	
	/// Creates a web-socket instance.
	///
	/// - Parameters:
	///   - connectionUrl: Endpoint that accepts a web-socket connection.
	///   - connectionHeaders: Additional connection headers.
	///   - timeIntervalForTimeout: Connection timeout. Default is 10 seconds.
	///   - timeIntervalForPing: Autoping interval. Default is 10 seconds.
	///   - receivedMessageTypes: Array or types that should be decoded from a received message in the given order.
	///   - receivedMessageJSONDecoder: JSON decoder for received messages.
	///   - eventHandler: Closure to handle received events.
	public init(
		connectionUrl: URL,
		connectionHeaders: [String: String] = [:],
		connectionTimeout timeIntervalForTimeout: TimeInterval = 10,
		autoPingInterval timeIntervalForPing: TimeInterval = 10,
		receivedMessageTypes: [Decodable.Type] = [],
		receivedMessageJSONDecoder: JSONDecoder = JSONDecoder(),
		eventHandler: @escaping (STOMPSocket, Event) -> Void = { _, _ in }
	) {
		self.stompClient = SwiftStomp(
			host: connectionUrl,
			headers: connectionHeaders
		)
		self.timeIntervalForTimeout = timeIntervalForTimeout
		self.timeIntervalForPing = timeIntervalForPing
		self.receivedMessageTypes = receivedMessageTypes
		self.receivedMessageJSONDecoder = receivedMessageJSONDecoder
		self.eventHandler = eventHandler
	}
	
	// MARK: Exposed methods

	/// Connects web-socket. Ensures the STOMP sub-protocol is not connected.
	/// - throws: `STOMPSocket.Error.alreadyConnectedViaSTOMP`
	public func connect() throws {
		guard !isConnecting else {
			return
		}
		guard !isConnectedViaSTOMP else {
			throw Error.alreadyConnectedViaSTOMP
		}
		stompClient.delegate = self
		stompClient.connect(timeout: timeIntervalForTimeout, autoReconnect: true)
		eventHandler(self, .isConnecting)
	}
	
	/// Disconnectes web-socket. If `force` disconnection is chosen,
	/// the socket will just be destroyed and the server will not be notified.
	public func disconnect(force: Bool = false) {
		/// Set `autoReconnect` to `false` so that the socket will not try to reconnect.
		stompClient.autoReconnect = false
		stompClient.disconnect(force: force)
		if force {
			stompClient.delegate = nil
			eventHandler(self, .didDisconnect)
		}
	}
	
	/// Subscribes to a destination. Ensures the STOMP sub-protocol connection is established.
	/// - throws: `STOMPSocket.Error.notConnectedViaSTOMP`
	public func subscribe(to destination: String) throws {
		guard isConnectedViaSTOMP else {
			throw Error.notConnectedViaSTOMP
		}
		stompClient.subscribe(to: destination)
	}
	
	/// Unsubscribes from a destination. Ensures the STOMP sub-protocol connection is established.
	/// - throws: `STOMPSocket.Error.notConnectedViaSTOMP`
	public func unsubscribe(from destination: String) throws {
		guard isConnectedViaSTOMP else {
			throw Error.notConnectedViaSTOMP
		}
		stompClient.unsubscribe(from: destination)
	}
	
	/// Sends a payload to a destination. Ensures the STOMP sub-protocol connection is established.
	/// - throws: `STOMPSocket.Error.notConnectedViaSTOMP`
	public func send(payload: Encodable, to destination: String) throws {
		guard isConnectedViaSTOMP else {
			throw Error.notConnectedViaSTOMP
		}
		stompClient.send(body: payload, to: destination)
	}
	
}

// MARK: - STOMPSocket+SwiftStompDelegate

extension STOMPSocket: SwiftStompDelegate {
	
	public func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
		switch connectType {
		case .toSocketEndpoint:
			break
		case .toStomp:
			// Enable automatic pings iff connected via STOMP.
			stompClient.enableAutoPing(pingInterval: timeIntervalForPing)
			eventHandler(self, .didConnect)
		}
	}
	
	public func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
		switch disconnectType {
		case .fromSocket:
			eventHandler(self, .didDisconnect)
			stompClient.delegate = nil
		case .fromStomp:
			// If auto-connect is enabled, websocket will reconnect soon.
			// Otherwise, it will be completelly disconnected soon.
			break
		}
	}
	
	public func onMessageReceived(
		swiftStomp: SwiftStomp,
		message: Any?,
		messageId: String,
		destination: String,
		headers: [String: String]
	) {
		let messageData: Data? = {
			if let messageString = message as? String {
				return messageString.data(using: .utf8)
			} else if let messageData = message as? Data {
				return messageData
			} else {
				return nil
			}
		}()
		guard let messageData else {
			return
		}
		for decodeType in receivedMessageTypes {
			do {
				let decodedMessage = try receivedMessageJSONDecoder.decode(
					decodeType.self,
					from: messageData
				)
				eventHandler(self, .didReceivePayload(
					decodedMessage,
					from: destination
				))
				break
			} catch {
				//
			}
		}
	}
	
	public func onError(
		swiftStomp: SwiftStomp,
		briefDescription: String,
		fullDescription: String?,
		receiptId: String?,
		type: StompErrorType
	) {
		eventHandler(self, .didReceiveError(description: briefDescription))
	}

	public func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {

	}

	public func onSocketEvent(eventName: String, description: String) {

	}

}
