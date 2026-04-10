import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NetworkingMacrosPlugin: CompilerPlugin {
    var providingMacros: [any Macro.Type] {
        []
    }
}
