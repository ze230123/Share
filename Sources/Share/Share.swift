
import UIKit
import WXApi
import QQApi

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
    static func registerApp(wxCongigure: WXConfiguration, qqAppId: String) {
        WXApiManager.register(for: wxCongigure)
        QQApi.register(for: qqAppId)
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
                    let request = WXApi.friendRequest(url: request.url, title: request.title, description: request.description, image: image)
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
            let image = try request.image?.asImage()
            let request = WXApi.miniRequest(path: request.path, userName: request.username, title: request.title, description: request.description, image: image)
            WXApiManager.share(request) { reuslt in
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
}

public extension Share {
    enum Platform {
        case wxFriend
        case wxTimeline
        case qqFriend
        case qZone
    }

    struct Request {
        var platform: Share.Platform
        /// 消息标题
        var title: String
        /// 描述内容
        var description: String
        /// 分享的链接
        var url: String
        /// 缩略图
        var image: ShareImage
    }

    struct MiniProgramRequest {
        /// 小程序的页面路径
        var path: String
        /// 小程序的userName
        var username: String
        /// 小程序新版本的预览图
        var image: ShareImage?
        /// 消息标题
        var title: String
        /// 描述内容
        var description: String
    }
}

enum ShareImage {
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
