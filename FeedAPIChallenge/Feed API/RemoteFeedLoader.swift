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

	public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
		client.get(from: url, completion: { [weak self] result in

			guard self != nil else { return }

			switch result {
			case let .success((data, response)):
				completion(FeedImageMapper.map(data, response))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		})
	}
}

private final class FeedImageMapper {
	private struct Root: Decodable {
		var items: [Item]
	}

	private struct Item: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var item: FeedImage {
			return FeedImage(id: image_id,
			                 description: image_desc,
			                 location: image_loc,
			                 url: image_url)
		}
	}

	private static var OK_200: Int { return 200 }

	static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == OK_200,
		      let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}

		let items = root.items.map(\.item)
		return .success(items)
	}
}
