
import UIKit
import WXApi
import QQApi
import RxSwift
import RxCocoa

public typealias WXApiManager = WXApi.WXApiManager

public enum ShareResult {
    case success
    case failure(Error)
}

enum ShareError: Error {
    case failure
    case imageNil
    case imageUrl
    case imageLoad
}

extension ShareError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failure:
            return "分享失败"
        case .imageNil:
            return "缺少分享图片"
        case .imageUrl:
            return "图片URL初始化失败"
        case .imageLoad:
            return "加载图片失败"
        }
    }
}

public class Share {
    /// 单利
    private static var shared: Share!
    /// 小程序版本
    private let miniType: WXApi.ProgramType

    /// 初始化方法
    /// - Parameters:
    ///   - miniType: 小程序版本类型
    private init(type: String) {
        let miniType = WXApi.ProgramType.init(rawValue: type) ?? .release
        self.miniType = miniType
    }

    public static func registerApp(wxCongigure: WXConfiguration, qqAppId: String, miniType: String) {
        WXApiManager.register(for: wxCongigure)
        QQApi.register(for: qqAppId)
        shared = Share(type: miniType)
    }

    public static func send(_ request: Share.Request, complation: ((ShareResult) -> Void)?) {
        _ = request.image.asRxImage()
            .debug("【Share】")
            .observe(on: MainScheduler.instance)
            .flatMapLatest { image -> Observable<ShareResult> in
                switch request.platform {
                case .wxFriend:
                    let req = WXApi.friendRequest(url: request.url, title: request.title, description: request.description, image: image)
                    return WXApiManager.rxSend(req)
                case .wxTimeline:
                        let req = WXApi.timelineRequest(url: request.url, title: request.title, description: request.description, image: image)
                    return WXApiManager.rxSend(req)
                case .qqFriend:
                    let req = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                    return QQApi.rxShareQQ(req)
                case .qZone:
                    let req = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                    return QQApi.rxShareQZone(req)
                case .miniProgram:
                    let req = WXApi.miniRequest(path: request.url, userName: request.userName, title: request.title, description: request.description, image: image, type: shared.miniType)
                    return WXApiManager.rxSend(req)
                }
            }
            .subscribe { result in
                DispatchQueue.main.async {
                    complation?(result)
                }
            }
    }

    public static func send(_ request: Share.LaunchMiniRequest) {
        let req = WXApi.launchMiniRequest(path: request.path, userName: request.username, miniType: shared.miniType)
        WXApiManager.share(req, complation: nil)
    }

    public static func sendImage(_ image: Data, platform: Share.Platform, complation: ((ShareResult) -> Void)?) {
        switch platform {
        case .wxFriend:
            let req = WXApi.friendImageRequest(imageData: image)
            WXApiManager.share(req) { reuslt in
                switch reuslt {
                case .success:
                    complation?(.success)
                case .failure:
                    complation?(.failure(ShareError.failure))
                }
            }
        case .wxTimeline:
            let req = WXApi.timelineImageRequest(imageData: image)
            WXApiManager.share(req) { reuslt in
                switch reuslt {
                case .success:
                    complation?(.success)
                case .failure:
                    complation?(.failure(ShareError.failure))
                }
            }
        case .qqFriend:
            let request = QQApi.imageRequest(imageData: image)
            QQApi.shareQQ(req: request) { result in
                switch result {
                case .success:
                    complation?(.success)
                case .failure:
                    complation?(.failure(ShareError.failure))
                }
            }
        default:
            break
        }
    }

    public static func handleOpenURL(_ url: URL) -> Bool {
        _ = QQApi.handleOpen(url)
        _ = WXApiManager.handleOpen(url)
        return true
    }
}

extension WXApiManager {
    static func rxSend(_ req: BaseReq) -> Observable<ShareResult> {
        return Observable.create { observer in
            WXApiManager.share(req) { result in
                switch result {
                case .success:
                    observer.onNext(ShareResult.success)
                case .failure:
                    observer.onNext(ShareResult.failure(ShareError.failure))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

extension QQApi {
    static func rxShareQQ(_ req: QQBaseReq) -> Observable<ShareResult> {
        return Observable.create { observer in
            QQApi.shareQQ(req: req) { result in
                switch result {
                case .success:
                    observer.onNext(ShareResult.success)
                case .failure:
                    observer.onNext(ShareResult.failure(ShareError.failure))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    static func rxShareQZone(_ req: QQBaseReq) -> Observable<ShareResult> {
        return Observable.create { observer in
            QQApi.shareQZone(req: req) { result in
                switch result {
                case .success:
                    observer.onNext(ShareResult.success)
                case .failure:
                    observer.onNext(ShareResult.failure(ShareError.failure))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

extension Share {
    public enum Platform {
        case wxFriend
        case wxTimeline
        case qqFriend
        case qZone
        case miniProgram

        public var desc: String {
            switch self {
            case .wxFriend:
                return "微信好友"
            case .wxTimeline:
                return "微信朋友圈"
            case .qqFriend:
                return "QQ好友"
            case .qZone:
                return "QQ空间"
            case .miniProgram:
                return "微信小程序"
            }
        }
    }

    /// QQ、微信、小程序分享模型
    public struct Request {
        var platform: Share.Platform
        /// 消息标题
        var title: String
        /// 描述内容
        var description: String
        /// 分享的链接
        var url: String
        /// 缩略图
        var image: ShareImage
        /// 小程序名、不分享小程序不用传
        var userName: String?

        public init(platform: Share.Platform, url: String, image: ShareImage, title: String, description: String, userName: String? = nil) {
            self.platform = platform
            self.url = url
            self.image = image
            self.title = title
            self.description = description
            self.userName = userName
        }
    }

    /// 分享图片模型
    public struct ImageRequest {
        let imageData: Data

        public init(imageData: Data) {
            self.imageData = imageData
        }
    }

    public struct LaunchMiniRequest {
        var path: String
        var username: String

        public init(path: String, username: String) {
            self.path = path
            self.username = username
        }
    }
}

public enum ShareImage {
    case image(UIImage?)
    case url(String)
}

extension ShareImage {
    func asRxImage() -> Observable<UIImage> {
        switch self {
        case .image(let optional):
            return Observable.create { observer in
                if let image = optional {
                    observer.onNext(image)
                    observer.onCompleted()
                } else {
                    observer.onError(ShareError.imageNil)
                }
                return Disposables.create()
            }
        case .url(let str):
            guard let value = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: value) else {
                return .error(ShareError.imageUrl)
            }

            let request = URLRequest(url: url)
            return URLSession.shared.rx
                .response(request: request)
                .map { result -> UIImage in
                    guard let image = UIImage(data: result.data) else {
                        throw ShareError.imageLoad
                    }
                    return ShareImage.compressImage(image, toByte: 1024 * 6)
                }
        }
    }

    static func compressImage(_ image: UIImage, toByte maxLength: Int) -> UIImage {
        var compression: CGFloat = 1
        guard var data = image.jpegData(compressionQuality: compression),
            data.count > maxLength else { return image }

        // Compress by size
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            data = image.jpegData(compressionQuality: compression)!
            if CGFloat(data.count) < CGFloat(maxLength) * 0.9 {
                min = compression
            } else if data.count > maxLength {
                max = compression
            } else {
                break
            }
        }
        var resultImage: UIImage = UIImage(data: data)!
        if data.count < maxLength {
            return resultImage
        }

        // Compress by size
        var lastDataLength: Int = 0
        while data.count > maxLength, data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(maxLength) / CGFloat(data.count)
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)),
                                    height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            data = resultImage.jpegData(compressionQuality: compression)!
        }
        return resultImage
    }

//    func asImage() throws -> UIImage {
//        switch self {
//        case .image(let optional):
//            guard let image = optional else {
//                throw ShareError.imageNil
//            }
//            return image
//        case .url(let string):
//            guard let value = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//                throw ShareError.imageNil
//            }
//            guard let url = URL(string: value) else {
//                throw ShareError.imageUrl
//            }
//            let data = try Data(contentsOf: url)
//            guard let image = UIImage(data: data, scale: 1) else {
//                throw ShareError.imageLoad
//            }
//            return image
//        }
//    }
}
