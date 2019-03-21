//
//  AuthProvider.swift
//  UpcomingMovies
//
//  Created by Alonso on 3/20/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation

enum AuthProvider {
    
    case requestToken
    
}

// MARK: - Endpoint

extension AuthProvider: Endpoint {
    
    var base: String {
        return "https://api.themoviedb.org"
    }
    
    var path: String {
        switch self {
        case .requestToken:
            return "/3/authentication/token/new"
        }
    }
    
    var params: [String: Any]? {
        switch self {
        case .requestToken:
            return nil
        }
    }
    
}
