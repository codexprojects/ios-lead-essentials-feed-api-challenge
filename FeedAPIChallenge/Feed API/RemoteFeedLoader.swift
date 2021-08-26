//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url, completion: { result in
			switch result {
			case let .success((data, response)):
				guard response.statusCode == 200 else {
					completion(.failure(Error.invalidData))
					return
				}

				if let _ = try? JSONDecoder().decode(Root.self, from: data) {} else {
					completion(.failure(Error.invalidData))
				}
			default:
				completion(.failure(Error.connectivity))
			}
		})
	}
}

private struct Root: Decodable {
	var items: [Item]
}

private struct Item: Decodable {
	let imageId: UUID
	let imageDesc: String?
	let imageLoc: String?
	let imageUrl: URL

	var item: FeedImage {
		return FeedImage(id: imageId,
		                 description: imageDesc,
		                 location: imageLoc,
		                 url: imageUrl)
	}
}
