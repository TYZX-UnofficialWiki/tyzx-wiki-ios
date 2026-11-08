import AppKit
let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let source = NSImage(contentsOf: sourceURL)!
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(CGColor(gray: 1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
let cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil)!
let width: CGFloat = 944
let height = width * CGFloat(cg.height) / CGFloat(cg.width)
ctx.interpolationQuality = .high
ctx.draw(cg, in: CGRect(x: (1024-width)/2, y: (1024-height)/2, width: width, height: height))
let data = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
try data.write(to: outputURL)
