//
//  HelpView.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit

/// 이미지 확대/축소를 지원하는 커스텀 UIScrollView입니다.
///
/// - 이미지 설정 시 자동으로 zoom scale과 중앙 정렬이 적용됩니다.
/// - 최대 5배까지 줌이 가능하며, 확대 시 이미지가 중앙에 위치합니다.
///
/// ## 주요 기능
/// - setImage(_:)로 이미지 설정
/// - updateZoomScale(for:)로 Zoom Scale 계산
/// - layoutSubviews에서 이미지 중앙 정렬
final class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    
    // MARK: - Properties
    
    var index: Int = 0 // 외부 리스트에서 식별용
    private(set) var imageView: UIImageView!
    var originalImage: UIImage?
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureScrollView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureScrollView()
    }
    
    // MARK: - UI Setup
    private func configureScrollView() {
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        delaysContentTouches = false
    }
    
    // MARK: - Public API
    
    func setImage(_ image: UIImage) {
        originalImage = image
        imageView?.removeFromSuperview()
        
        imageView = UIImageView(image: image)
        addSubview(imageView)
        
        zoomScale = 1.0
        updateZoomScale(for: image.size)
    }
    
    // MARK: - Zoom Configuration
    
    private func updateZoomScale(for imageSize: CGSize) {
        let boundsSize = bounds.size
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        var minScale = min(xScale, yScale)
        let maxScale: CGFloat = 5.0
        
        if minScale > maxScale {
            minScale = maxScale
        }
        
        minimumZoomScale = minScale
        maximumZoomScale = maxScale
        zoomScale = minScale
        
        let imageViewSize = CGSize(
            width: boundsSize.width,
            height: (boundsSize.width * imageSize.height) / imageSize.width
        )
        contentSize = imageViewSize
    }
    
    // MARK: - Centering Logic
    
    private func centerImageView() {
        let boundsSize = bounds.size
        var frame = imageView.frame
        
        frame.origin.x = (frame.width < boundsSize.width)
        ? (boundsSize.width - frame.width) / 2
        : 0
        
        frame.origin.y = (frame.height < boundsSize.height)
        ? (boundsSize.height - frame.height) / 2
        : 0
        
        imageView.frame = frame
    }
    
    // layoutSubviews 호출 시 이미지 중앙 정렬
    override func layoutSubviews() {
        super.layoutSubviews()
        centerImageView()
    }
    
    // MARK: - UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
