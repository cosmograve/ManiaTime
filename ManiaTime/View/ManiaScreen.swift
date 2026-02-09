import SwiftUI

struct ManiaScreen<
    Background: View,
    Center: View,
    LeftTop: View,
    RightTop: View
>: View {
    
    // MARK: - Layout
    
    private let sideImageHeightRatio: CGFloat
    private let topInset: CGFloat
    private let topBarHeight: CGFloat
    
    private let sideEdgePadding: CGFloat
    
    private let centerWidth: CGFloat?
    private let centerWidthRatio: CGFloat?
    
    private let background: Background
    private let center: Center
    private let leftTop: LeftTop
    private let rightTop: RightTop
    
    
    init(
        sideImageHeightRatio: CGFloat = 0.50,
        topInset: CGFloat = 0,
        topBarHeight: CGFloat = 80,
        sideEdgePadding: CGFloat = 0,
        centerWidth: CGFloat? = nil,
        centerWidthRatio: CGFloat? = 0.52,
        @ViewBuilder background: () -> Background,
        @ViewBuilder center: () -> Center,
        @ViewBuilder leftTop: () -> LeftTop = { EmptyView() },
        @ViewBuilder rightTop: () -> RightTop = { EmptyView() }
    ) {
        self.sideImageHeightRatio = sideImageHeightRatio
        self.topInset = topInset
        self.topBarHeight = topBarHeight
        self.sideEdgePadding = sideEdgePadding
        self.centerWidth = centerWidth
        self.centerWidthRatio = centerWidthRatio
        self.background = background()
        self.center = center()
        self.leftTop = leftTop()
        self.rightTop = rightTop()
    }
    
    
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let sideH = h * sideImageHeightRatio
            
            let centerMaxW: CGFloat? = {
                if let centerWidth { return centerWidth }
                if let centerWidthRatio { return w * centerWidthRatio }
                return nil
            }()
            
            ZStack {
                background
                    .frame(width: w, height: h)
                    .clipped()
                
                HStack(spacing: 0) {
                    
                    // LEFT
                    VStack(spacing: 0) {
                        leftTop
                            .frame(height: topBarHeight, alignment: .topLeading)
                            .padding(.top, topInset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, sideEdgePadding)
                        
                        Spacer(minLength: 0)
                        
                        Image(.maniaMenuL)
                            .resizable()
                            .scaledToFit()
                            .frame(height: sideH)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, sideEdgePadding) 
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding()
                    
                    
                    Spacer(minLength: 0)
                    
                    // RIGHT
                    VStack(spacing: 0) {
                        rightTop
                            .frame(height: topBarHeight, alignment: .topTrailing)
                            .padding(.top, topInset)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, sideEdgePadding)
                        
                        Spacer(minLength: 0)
                        
                        Image(.maniaMenuR)
                            .resizable()
                            .scaledToFit()
                            .frame(height: sideH)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, sideEdgePadding)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding()
                }
                .ignoresSafeArea()
                
                center
                    .frame(maxWidth: centerMaxW)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .ignoresSafeArea()
        }
    }
}
