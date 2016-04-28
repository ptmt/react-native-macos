import Foundation

public func JSONStringify(jsonObject: AnyObject) -> String {
    if NSJSONSerialization.isValidJSONObject(jsonObject) {
        if let jsonData = try? NSJSONSerialization.data(withJSONObject: jsonObject) {
            if let string = String(data: jsonData, encoding: NSUTF8StringEncoding) {
                return string
            }
        }
    }
    return "";
}