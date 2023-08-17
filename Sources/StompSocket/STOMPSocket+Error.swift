//
//  Created by Roman Nabiullin
//
//  Copyright (c) 2023 - Present
//
//  All Rights Reserved.
//

import Foundation

// MARK: - Error

extension STOMPSocket {
	
	public enum Error: Swift.Error, Equatable, Sendable {
		
		// MARK: Case
		
		case alreadyConnectedViaSTOMP
		
		case notConnectedViaSTOMP
		
	}
	
}
