//
//  TimelineContent.swift
//  UI Component
//
//  Created by Jiaxin Pu on 2022/9/8.
//

import Foundation

enum TimelineContentType: Codable {
    case singleMessage(message: String)
    case singlePhoto(photo: String, message: String?)
}

struct TimelineContent: Identifiable, Codable {
    
    struct Image: Codable {
        let url: String
    }
    
    struct Comment: Codable {
        let sender: Sender
    }
    
    struct Sender: Codable {
        let nick: String
        let avatar: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case sender
        case comments
        case images
        case content
    }
    
    let id: Int
    let nickname: String
    let avatarUrl: String
    let type: TimelineContentType
    let likes: [String]
    
    init(
        id: Int,
        nickname: String,
        avatarUrl: String,
        type: TimelineContentType,
        likes: [String]
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarUrl = avatarUrl
        self.type = type
        self.likes = likes
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: CodingKeys.id)
        try container.encode(Sender(nick: nickname, avatar: avatarUrl), forKey: CodingKeys.sender)
        
        switch type {
        case .singleMessage(let message):
            try container.encode(message, forKey: CodingKeys.content)
            
        case .singlePhoto(let photo, let message):
            try container.encodeIfPresent(message, forKey: CodingKeys.content)
            try container.encode([Image(url: photo)], forKey: CodingKeys.images)
        }
        
        let comments = likes.map { name in
            Comment(sender: Sender(nick: name, avatar: ""))
        }
        
        try container.encode(comments, forKey: CodingKeys.comments)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: CodingKeys.id)
        
        let sender = try container.decode(Sender.self, forKey: CodingKeys.sender)
        (nickname, avatarUrl)  = (sender.nick, sender.avatar)
        
        let content = try container.decodeIfPresent(String.self, forKey: CodingKeys.content)
        let images = try container.decodeIfPresent(Array<Image>.self, forKey: CodingKeys.images)
        if let image = images?.first?.url {
            type = .singlePhoto(photo: image, message: content)
        } else {
            type = .singleMessage(message: content ?? "")
        }
        
        let comments = try container.decodeIfPresent(Array<Comment>.self, forKey: CodingKeys.comments)
        likes = comments?.map(\.sender.nick) ?? []
    }
}
 
enum Catch<T: Decodable> : Decodable {
    
    case success(T)
    case failure(Error)

    init(from decoder: Decoder) throws {
        do {
            self = .success(try decoder.singleValueContainer().decode(T.self))
        } catch let error {
            self = .failure(error)
        }
    }
    
    var value: T? {
        switch self {
        case .success(let t): return t
        case .failure: return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .success: return  nil
        case .failure(let error): return error
        }
    }
}


