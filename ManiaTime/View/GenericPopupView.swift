

import SwiftUI

struct GenericPopupView: View {

    let title: String
    let subtitle: String
    let coins: Int
    let buttonTitle: String
    let onTap: () -> Void

    var body: some View {
        ManiaScreen(
            sideEdgePadding: 12,
            centerWidthRatio: 0.62,
            background: { Color.black.opacity(0.001) },
            center: {
                ZStack {
                    Image(.contentRect)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 12) {
                        Text(title)
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)

                        Text("+\(coins) coins")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.yellow)

                        Button {
                            onTap()
                        } label: {
                            Text(buttonTitle)
                                .font(.system(size: 20, weight: .bold))
                                .padding(.vertical, 14)
                                .padding(.horizontal, 26)
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        )
        .ignoresSafeArea()
    }
}
