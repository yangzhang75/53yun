//
//  RecipeRecommending.swift
//  AICompanionCore
//
//  推荐器抽象：本地规则引擎与大模型实现皆遵循此协议，可互换 / 兜底。
//

import Foundation

public protocol RecipeRecommending: Sendable {
    /// 根据自然语言诉求给出一条推荐。
    /// - Throws: `BartenderError`
    func recommend(for query: BartenderQuery) async throws -> Recommendation
}
