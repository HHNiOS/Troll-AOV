//
//  DisclaimerView.swift
//  TrollFools
//
//  Created by 82Flex on 3/13/25.
//

import SwiftUI

struct DisclaimerView: View {
    @Binding var isDisclaimerHidden: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("""
                    Phần mềm này chỉ được cung cấp cho mục đích trao đổi kỹ thuật và học tập trong nghiên cứu công nghệ. Chúng tôi không chịu trách nhiệm về bất kỳ thiệt hại nào phát sinh từ việc sử dụng phần mềm này, bao gồm nhưng không giới hạn ở thiệt hại về dữ liệu, phần cứng hoặc phần mềm. Người dùng phải tự chịu trách nhiệm về việc sử dụng phần mềm này và tuân thủ tất cả các luật và quy định liên quan. Chúc bạn may mắn!!
                    """)
                }
                .padding()
                .font(.body)
            }
            .navigationTitle("Điều Khoản")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        exit(EXIT_SUCCESS)
                    } label: {
                        VStack(spacing: 0) {
                            Text("Thoát")
                                .font(.body)
                                .fontWeight(.bold)
                            Text("Exit")
                                .font(.footnote)
                        }
                        .foregroundColor(.red)
                        .padding()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        isDisclaimerHidden = true
                    } label: {
                        VStack(spacing: 0) {
                            Text("Tôi đã đọc và đồng ý")
                                .font(.body)
                                .fontWeight(.bold)
                            Text("I Have Read and Agree")
                                .font(.footnote)
                        }
                        .foregroundColor(.accentColor)
                        .padding()
                    }
                }
            }
        }
    }
}
