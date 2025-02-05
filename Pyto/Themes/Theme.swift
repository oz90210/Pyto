//
//  EditorTheme_.swift
//  Pyto
//
//  Created by Adrian Labbé on 1/15/19.
//  Copyright © 2019 Adrian Labbé. All rights reserved.
//

import SourceEditor
import SavannaKit
import UIKit

/// A protocol for implementing an editor and console theme.
protocol Theme {
    
    /// The keyboard appearance used in the editor and the console.
    var keyboardAppearance: UIKeyboardAppearance { get }
    
    /// The navigation and tool bar style.
    var barStyle: UIBarStyle { get }
    
    /// The source code theme type.
    var sourceCodeTheme: SourceCodeTheme { get }
    
    /// The user interface style applied to the editor and the console.
    var userInterfaceStyle: UIUserInterfaceStyle { get }
    
    /// The tint color of the interface.
    var tintColor: UIColor? { get }
    
    /// The name of the theme if created by user.
    var name: String? { get }
    
    /// The data corresponding to the theme.
    var data: Data { get }
}

extension Theme {
    
    var tintColor: UIColor? {
        return UIColor(named: "TintColor")
    }
    
    var name: String? {
        return nil
    }
    
    var data: Data {
        var str = ""
        
        str += name ?? ""
        str += "\n"
        
        if userInterfaceStyle == .dark {
            str += "dark\n"
        } else if userInterfaceStyle == .light {
            str += "light\n"
        } else {
            str += "default\n"
        }
        
        str += "\((tintColor ?? UIColor(named: "TintColor") ?? .systemGreen).encode().base64EncodedString())\n"
        
        let tokens: [SourceCodeTokenType] = [.comment, .editorPlaceholder, .identifier, .keyword, .number, .plain, .string]
        
        for token in tokens {
            str += "\(sourceCodeTheme.color(for: token).encode().base64EncodedString())\n"
        }
        
        str += "\(sourceCodeTheme.backgroundColor.encode().base64EncodedString())\n"
        
        return str.data(using: .utf8) ?? Data()
    }
}

/// Returns a theme from given data.
///
/// - Parameters:
///     - data: Data from `Theme.data`
///
/// - Returns: Decoded theme.
func ThemeFromData(_ data: Data) -> Theme? {
    
    guard let str = String(data: data, encoding: .utf8) else {
        return nil
    }
    
    let comp = str.components(separatedBy: "\n")
    
    guard comp.count >= 11 else {
        return nil
    }
    
    struct CustomSourceCodeTheme: SourceCodeTheme {
        
        static func decodedColor(from string: String) -> UIColor {
            if let data = Data(base64Encoded: string) {
                return UIColor.color(withData: data)
            } else {
                return .black
            }
        }
        
        let defaultTheme = DefaultSourceCodeTheme()
        
        var comp: [String]
        
        func color(for syntaxColorType: SourceCodeTokenType) -> Color {
            switch syntaxColorType {
            case .comment:
                return CustomSourceCodeTheme.decodedColor(from: comp[3])
            case .editorPlaceholder:
                return CustomSourceCodeTheme.decodedColor(from: comp[4])
            case .identifier:
                return CustomSourceCodeTheme.decodedColor(from: comp[5])
            case .keyword:
                return CustomSourceCodeTheme.decodedColor(from: comp[6])
            case .number:
                return CustomSourceCodeTheme.decodedColor(from: comp[7])
            case .plain:
                return CustomSourceCodeTheme.decodedColor(from: comp[8])
            case .string:
                return CustomSourceCodeTheme.decodedColor(from: comp[9])
            }
        }
        
        func globalAttributes() -> [NSAttributedString.Key : Any] {
            
            var attributes = [NSAttributedString.Key: Any]()
            
            attributes[.font] = font
            attributes[.foregroundColor] = color(for: .plain)
            
            return attributes
        }
        
        var lineNumbersStyle: LineNumbersStyle? {
            return defaultTheme.lineNumbersStyle
        }
        
        var gutterStyle: GutterStyle {
            return GutterStyle(backgroundColor: backgroundColor, minimumWidth: defaultTheme.gutterStyle.minimumWidth)
        }
        
        var font: Font {
            return EditorViewController.font.withSize(CGFloat(ThemeFontSize))
        }
        
        var backgroundColor: Color {
            return CustomSourceCodeTheme.decodedColor(from: comp[10])
        }
    }
    
    let name = comp[0]
    let userInterfaceStyle: UIUserInterfaceStyle = (comp[1] == "dark" ? .dark : (comp[1] == "light" ? .light : .unspecified))
    let tint = CustomSourceCodeTheme.decodedColor(from: comp[2])
    
    struct CustomTheme: Theme {
        var keyboardAppearance: UIKeyboardAppearance
        
        var barStyle: UIBarStyle
        
        var sourceCodeTheme: SourceCodeTheme
        
        var userInterfaceStyle: UIUserInterfaceStyle
        
        var name: String?
        
        var tintColor: UIColor?
    }
    
    return CustomTheme(keyboardAppearance: (userInterfaceStyle == .dark ? .dark : (userInterfaceStyle == .light ? .light : .default)), barStyle: (userInterfaceStyle == .dark ? .black : .default), sourceCodeTheme: CustomSourceCodeTheme(comp: comp), userInterfaceStyle: userInterfaceStyle, name: name, tintColor: tint)
}

/// A dictionary with all themes.
var Themes: [(name: String, value: Theme)] {
    var themes: [(name: String, value: Theme)] = [
        (name: "Default", value: DefaultTheme()),
        (name: "Xcode Light", value: XcodeLightTheme()),
        (name: "Xcode Dark", value: XcodeDarkTheme()),
        (name: "Basic", value: BasicTheme()),
        (name: "Dusk", value: DuskTheme()),
        (name: "LowKey", value: LowKeyTheme()),
        (name: "Midnight", value: MidnightTheme()),
        (name: "Sunset", value: SunsetTheme()),
        (name: "WWDC16", value: WWDC16Theme()),
        (name: "Cool Glow", value: CoolGlowTheme()),
        (name: "Solarized Light", value: SolarizedLightTheme()),
        (name: "Solarized Dark", value: SolarizedDarkTheme())
    ]
    
    if #available(iOS 13.0, *) {
        for theme in ThemeMakerTableViewController.themes {
            themes.append((name: theme.name ?? "", value: theme))
        }
    }
    
    return themes
}

/// A notification sent when the user choosed theme.
let ThemeDidChangeNotification = Notification.Name("ThemeDidChangeNotification")

/// The font size used on the editor.
var ThemeFontSize: Int {
    get {
        return (UserDefaults.standard.value(forKey: "fontSize") as? Int) ?? 15
    }
    
    set {
        UserDefaults.standard.set(newValue, forKey: "fontSize")
        UserDefaults.standard.synchronize()
    }
}
