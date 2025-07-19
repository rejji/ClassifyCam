//
//  WishListView.swift
//  AVCam
//
//  Created by Rajeev Bakshi on 21/10/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct WishListView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("We Value Your Wishlist!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("""
                    We're committed to making your experience with our app better. Your wishlist helps us shape the future of this app.
                    
                    Please let us know:
                    * What features would you love to see next?
                    * What functionalities do you think would enhance your experience?
                    * Any specific improvements or additions you would like us to consider?
                    * How are you using our app? What scenarios or projects are you working on that our app helps with?

                    Feel free to share your thoughts and suggestions!
                    """)
                .lineLimit(nil)
                .padding(.vertical, 5)
                .multilineTextAlignment(.leading)

                Text("""
                    Stay tuned for our next version rollout! It will allow users to recognize specific sounds by uploading corresponding sound files, utilizing machine learning. Additionally, users will be able to tag relevant information about the detected sounds within the captured files.
                    """)
                
                Text("Send us an email at:")
                    .fontWeight(.semibold)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Link("info_classifycam", destination: URL(string: "mailto:info_classifycam_a91r@curvsort.com")!)
                        .foregroundColor(.blue)
                }
                
                Text("We'll be updating this email address every quarter, so don't hesitate to reach out while it's active. Your input is invaluable to us - thank you for helping us build something amazing!")
                    .padding(.top, 10)

                Spacer()
            }
            .padding()
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    WishListView()
}
