//
//  TimelineContentViewModel.swift
//  UI Component
//
//  Created by Jiaxin Pu on 2022/9/8.
//

import Foundation
import Combine
import Alamofire

final class TimelineContentViewModel: ObservableObject {
    @Published private(set) var contents: [TimelineContent] = []
    private let decoder = JSONDecoder()
    private var cacheURL: URL = {
        let cacheDirectoryPath = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("contents.data")
        return cacheDirectoryPath
    }()
    
    func loadData(profile: Profile) {
        if let cache = loadCache() {
            print("load cache")
            contents = cache
        } else {
            loadWithAlamofire { content in
                self.contents = content
        
                DispatchQueue.global().async {
                    print("write cache")
                    self.writeCache()
                }
            }
        }
    }
    
    private func loadWithURLSession(completion: @escaping ([TimelineContent]) -> ()) {
        if let url = URL(string: "https://thoughtworks-mobile-2018.herokuapp.com/user/jsmith/tweets") {
            URLSession.shared.dataTask(with: url) { d, _, _ in
                if let data = d {
                    do {
                        let content = try self.decoder.decode(Array<Catch<TimelineContent>>.self, from: data).compactMap { $0.value }
                        completion(content)
                    } catch _ {
                        completion([])
                    }
                } else {
                    completion([])
                }
            }
        } else {
            completion([])
        }
    }
    
    private func loadWithAlamofire(completion: @escaping ([TimelineContent]) -> ()) {
        let url = "https://thoughtworks-mobile-2018.herokuapp.com/user/jsmith/tweets"
        Session.default.request(url)
            .responseDecodable(of: Array<Catch<TimelineContent>>.self) { response in
                completion(response.value.map { content in content.compactMap { $0.value } }  ?? [])
            }
    }
    
    func writeCache(){
        do {
            let data = try JSONEncoder().encode(self.contents)
            try data.write(to: cacheURL)
//            print(cacheURL)
        } catch let error {
            print(error)
        }
    }
    
    func loadCache()-> [TimelineContent]?{
        if let data = try? Data(contentsOf: cacheURL) {
            return try? self.decoder.decode(Array<TimelineContent>.self, from: data)
        } else {
            return nil
        }
    }
}
