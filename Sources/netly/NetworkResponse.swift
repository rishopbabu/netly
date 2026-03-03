//
//  NetworkResponse.swift
//  netly
//
//  Created by Rishop Babu on 03/03/26.
//

import Foundation

struct CommonAPIResponse: Decodable {
	let status: String?
	let message: String
}
