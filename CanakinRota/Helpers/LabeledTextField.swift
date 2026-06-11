//
//  LabeledTextField.swift
//  RecipeBook
//
//  Created by Lee Simmons on 11/11/2024.
//

import SwiftUI

struct LabeledTextField: View {
    let label: String
    let helperText: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(label, text: $text)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
          
            if text.isEmpty {
                Text(helperText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}


