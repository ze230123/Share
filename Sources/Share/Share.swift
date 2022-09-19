
import UIKit
import WXApi
import QQApi

public typealias WXApiManager = WXApi.WXApiManager

public enum ShareResult {
    case success
    case failure(Error)
}

enum ShareError: Error {
    case failure
    case imageNil
}

extension ShareError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failure:
            return "分享失败"
        case .imageNil:
            return "分享图片错误"
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
        do {
            let image = try request.image.asImage()
            switch request.platform {
            case .wxFriend:
                let request = WXApi.friendRequest(url: request.url, title: request.title, description: request.description, image: image)
                WXApiManager.share(request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure(ShareError.failure))
                    }
                }
            case .wxTimeline:
                    let request = WXApi.timelineRequest(url: request.url, title: request.title, description: request.description, image: image)
                    WXApiManager.share(request) { result in
                        switch result {
                        case .success:
                            complation?(.success)
                        case .failure:
                            complation?(.failure(ShareError.failure))
                        }
                    }
            case .qqFriend:
                let request = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                QQApi.shareQQ(req: request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure(ShareError.failure))
                    }
                }
            case .qZone:
                let request = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                QQApi.shareQZone(req: request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure(ShareError.failure))
                    }
                }
            case .miniProgram:
                let req = WXApi.miniRequest(path: request.url, userName: request.userName, title: request.title, description: request.description, image: image, type: shared.miniType)
                WXApiManager.share(req) { reuslt in
                    switch reuslt {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure(ShareError.failure))
                    }
                }
            }
        } catch {
            debugPrint("分享 error", error.localizedDescription)
            guard let errors = error as? ShareError else {
                complation?(.failure(ShareError.failure))
                return
            }
            complation?(.failure(errors))
        }
    }

    public static func send(_ request: Share.LaunchMiniRequest) {
        let req = WXApi.launchMiniRequest(path: request.path, userName: request.username)
        WXApiManager.share(req, complation: nil)
    }

    public static func handleOpenURL(_ url: URL) -> Bool {
        _ = QQApi.handleOpen(url)
        _ = WXApiManager.handleOpen(url)
        return true
    }
}

extension Share {
    public enum Platform {
        case wxFriend
        case wxTimeline
        case qqFriend
        case qZone
        case miniProgram
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

        public init(platform: Share.Platform, url: String, image: ShareImage, title: String, description: String, userName: String?) {
            self.platform = platform
            self.url = url
            self.image = image
            self.title = title
            self.description = description
            self.userName = userName
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
    func asImage() throws -> UIImage {
        switch self {
        case .image(let optional):
            guard let image = optional else {
                throw ShareError.imageNil
            }
            return image
        case .url(let string):
            guard let url = URL(string: string) else {
                throw ShareError.imageNil
            }
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                throw ShareError.imageNil
            }
            return image
        }
    }
}
