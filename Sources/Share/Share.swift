
import UIKit
import WXApi
import QQApi

public typealias WXApiManager = WXApi.WXApiManager

public enum ShareResult {
    case success
    case failure
}

enum ShareError: Error {
    case cancel
    case failure
    case imageNil
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

    public static func registerApp(wxCongigure: WXConfiguration, qqAppId: String, miniType: String) {        WXApiManager.register(for: wxCongigure)
        QQApi.register(for: qqAppId)
        shared = Share(type: miniType)
    }

    public static func send(_ request: Share.Request, complation: ((ShareResult) -> Void)?) {
        do {
            switch request.platform {
            case .wxFriend:
                let image = try request.image.asImage()
                let request = WXApi.friendRequest(url: request.url, title: request.title, description: request.description, image: image)
                WXApiManager.share(request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure)
                    }
                }
            case .wxTimeline:
                    let image = try request.image.asImage()
                    let request = WXApi.timelineRequest(url: request.url, title: request.title, description: request.description, image: image)
                    WXApiManager.share(request) { result in
                        switch result {
                        case .success:
                            complation?(.success)
                        case .failure:
                            complation?(.failure)
                        }
                    }
            case .qqFriend:
                let image = try request.image.asImage()
                let request = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                QQApi.shareQQ(req: request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure)
                    }
                }
            case .qZone:
                let image = try request.image.asImage()
                let request = QQApi.shareRequest(url: request.url, title: request.title, description: request.description, imageData: image.pngData())
                QQApi.shareQZone(req: request) { result in
                    switch result {
                    case .success:
                        complation?(.success)
                    case .failure:
                        complation?(.failure)
                    }
                }
            }
        } catch {
            debugPrint("分享 error", error.localizedDescription)
            complation?(.failure)
        }
    }

    public static func send(_ request: Share.MiniProgramRequest, complation: ((ShareResult) -> Void)?) {
        do {
            let image = try request.image.asImage()
            let req = WXApi.miniRequest(path: request.path, userName: request.username, title: request.title, description: request.description, image: image, type: request.type)
            WXApiManager.share(req) { reuslt in
                switch reuslt {
                case .success:
                    complation?(.success)
                case .failure:
                    complation?(.failure)
                }
            }
        } catch {
            debugPrint("分享小程序 error", error.localizedDescription)
            complation?(.failure)
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
    }

    /// QQ、微信常规分享模型
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

        public init(platform: Share.Platform, url: String, image: ShareImage, title: String, description: String) {
            self.platform = platform
            self.url = url
            self.image = image
            self.title = title
            self.description = description
        }
    }

    /// 微信小程序分享模型
    public struct MiniProgramRequest {
        /// 小程序的页面路径
        var path: String
        /// 小程序的userName
        var username: String
        /// 小程序新版本的预览图
        var image: ShareImage
        /// 消息标题
        var title: String
        /// 描述内容
        var description: String

        /// 小程序版本
        var type: WXApi.ProgramType

        public init(path: String, username: String, image: ShareImage, title: String, description: String) {
            self.path = path
            self.username = username
            self.image = image
            self.title = title
            self.description = description
            self.type = Share.shared.miniType
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
            let data = try Data(contentsOf: URL(string: string)!)
            guard let image = UIImage(data: data) else {
                throw ShareError.imageNil
            }
            return image
        }
    }
}
