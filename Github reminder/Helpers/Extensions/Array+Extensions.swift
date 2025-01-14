//
//  Array+Extensions.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import Foundation

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}
