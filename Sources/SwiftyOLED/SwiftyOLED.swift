import SwiftyGPIO
#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

public protocol Drawable {
    var x: Int { get set }
    var y: Int { get set }
    
    //This method should return points for the actual shape
    //Do not add x and y offsets to these points
    func pointsForDrawing() -> [(Int, Int)]
}

public struct Square: Drawable {
    public var x: Int
    public var y: Int
    public var sideSize: Int
    
    public init(x: Int, y: Int, sideSize: Int) {
        self.x = x
        self.y = y
        self.sideSize = sideSize
    }
    
    public func pointsForDrawing() -> [(Int, Int)] {
        guard sideSize > 0 else {
            fatalError("Side size can not be smaller then or equal to zero")
        }
        
        var points = [(Int, Int)]()
        
        for i in stride(from: 0, to: sideSize, by: 1) { points.append((i, 0)) }
        for i in stride(from: 0, to: sideSize, by: 1) { points.append((sideSize, i)) }
        for i in stride(from: sideSize, to: 0, by: -1) { points.append((i, sideSize)) }
        for i in stride(from: sideSize, to: 0, by: -1) { points.append((0, i)) }
        
        return points
    }
}

public struct Rectangle: Drawable {
    public var x: Int
    public var y: Int
    public var a: Int
    public var b: Int
    
    public init(x: Int, y: Int, a: Int, b: Int) {
        self.x = x
        self.y = y
        self.a = a
        self.b = b
    }
    
    public func pointsForDrawing() -> [(Int, Int)] {
        guard a > 0 && b > 0 else {
            fatalError("Side size can not be smaller then or equal to zero")
        }
        
        var points = [(Int, Int)]()
        
        for i in stride(from: 0, to: a, by: 1) { points.append((i, 0)) }
        for i in stride(from: 0, to: b, by: 1) { points.append((a, i)) }
        for i in stride(from: a, to: 0, by: -1) { points.append((i, b)) }
        for i in stride(from: b, to: 0, by: -1) { points.append((0, i)) }
        
        return points
    }
}

public struct Circle: Drawable {
    public var x: Int
    public var y: Int
    public var radius: Int
    
    public init(x: Int, y: Int, radius: Int) {
        self.x = x
        self.y = y
        self.radius = radius
    }
    
    public func pointsForDrawing() -> [(Int, Int)] {
        guard radius > 0 else {
            fatalError("Radius can not be smaller then or equal to zero")
        }
        
        var points = [(Int, Int)]()
        
        for i in 0...2*radius {
            for j in 0...2*radius {
                let e1 = (i-radius)*(i-radius)
                let e2 = (j-radius)*(j-radius)
                let distanceToCenter: Double = sqrt(Double(e1+e2))
                if distanceToCenter > Double(radius) - 0.5
                && distanceToCenter < Double(radius) + 0.5 {
                    points.append((i, j))
                }
            }
        }
        return points
    }
}

public final class display  {
    
    private var buffer = Array<UInt8>(repeating: 0, count: 128*(32/8))
    private let i2c: I2CInterface
    private let address: Int
    
    enum Command: UInt8 {
        case SetContrast                            = 0x81
        case DisplayAllOnResume                     = 0xA4
        case DisplayAllOn                           = 0xA5
        case NormalDisplay                          = 0xA6
        case InvertDisplay                          = 0xA7
        case DisplayOff                             = 0xAE
        case DisplayOn                              = 0xAF
        case SetDisplayOffset                       = 0xD3
        case SetComPins                             = 0xDA
        case SetVComDetect                          = 0xDB
        case SetDisplayClockDiv                     = 0xD5
        case SetPrecharge                           = 0xD9
        case SetMultiplex                           = 0xA8
        case SetLowColumn                           = 0x00
        case SetHighColumn                          = 0x10
        case SetStartLine                           = 0x40
        case MemoryMode                             = 0x20
        case ColumnAddr                             = 0x21
        case PageAddr                               = 0x22
        case COMSCANINC                             = 0xC0
        case COMSCANDEC                             = 0xC8
        case SEGREMAP                               = 0xA0
        case ChargePump                             = 0x8D
        case ExternalVCC                            = 0x1
        case SwitchAPVCC                            = 0x2
        case ActivateScroll                         = 0x2F
        case DeactivateScroll                       = 0x2E
        case SetVerticalScrollArea                  = 0xA3
        case RightHorizontalScroll                  = 0x26
        case LeftHorizontalScroll                   = 0x27
        case VerticalAndRightHorizontalScroll       = 0x29
        case VerticalAndLeftHorizontalScroll        = 0x2A
    }
    public enum Brightness {
        case dimmed
        case bright
        case custom(value: UInt8)
    }
    public enum State {
        case on
        case off
    }
    
    
    
    //Please refere to page 10 (section 4.4) of UG-2832HSWEG02 datasheet for more info.
    func initialization() {
        self.turn(.off)
        send(command: .SetDisplayClockDiv)
        send(customCommand: 0x80)                                  // the suggested ratio 0x80
        send(command: .SetMultiplex)
        send(customCommand: 0x1F)
        send(command: .SetDisplayOffset)
        send(customCommand: 0x0)                                   // no offset
        send(customCommand: Command.SetStartLine.rawValue | 0x0)   // line #0
        send(command: .ChargePump)
        send(customCommand: 0x14)
        send(command: .MemoryMode)                                  // 0x20
        send(customCommand: 0x00)                                  // 0x0 act like ks0108
        send(customCommand: Command.SEGREMAP.rawValue | 0x1)
        send(command: .COMSCANDEC)
        send(command: .SetComPins)
        send(customCommand: 0x02)
        self.setBrightness(.custom(value: UInt8(0x8F)))
        send(command: .SetPrecharge)
        send(customCommand: 0xF1)
        send(command: .SetVComDetect)
        send(customCommand: 0x40)
        send(command: .DisplayAllOnResume)
        send(command: .NormalDisplay)
        self.turn(.on)
    }
    
    public init(on interface: I2CInterface, address: Int = 0x3C) {
        self.i2c = interface
        self.address = address
        initialization()
    }
    
    //Makes pixel at given coordinates white
    //Works in iPhone like coordinate system
    public func drawPixel(x: UInt8, y: UInt8){
        //since swift does not offer pow(Int, Int) conversion to double and back to UInt8 is necessary
        buffer[Int(y/8)*128+Int(x)] |= UInt8(pow(Double(2), Double(y%8)))
    }
    
    //Draw objets, which conforms to Drawable
    //Drawing outside screen is possible
    public func draw(_ object: Drawable) {
        object.pointsForDrawing().forEach({ [unowned self] point in
            let normalizedX = point.0 + object.x
            let normalizedY = point.1 + object.y
            
            if normalizedX >= 0 && normalizedX <= 127
            && normalizedY >= 0 && normalizedY <= 31 {
                self.drawPixel(x: UInt8(normalizedX), y: UInt8(normalizedY))
            }
        })
    }
    
    //Set the entire display buffer to white
    public func fill() {
        buffer = [UInt8](repeating: UInt8.max, count: 128*(32/8))
    }
    
    //Set the entire display buffer to black
    public func clear() {
        buffer = [UInt8](repeating: 0, count: 128*(32/8))
    }
    
    //Writes display buffer to physical display
    public func display() {
        send(command: Command.ColumnAddr)
        send(customCommand: 0)
        send(customCommand: 127)
        send(command: Command.PageAddr)
        send(customCommand: 0)
        send(customCommand: 3)
        sendBuffer()
    }
    
    //Sets brightness of display to either .dimmed or .bright
    public func setBrightness(_ brightness: Brightness) {
        switch brightness {
        case .dimmed:
            send(command: .SetContrast)
            send(customCommand: 0x00)
        case .bright:
            send(command: .SetContrast)
            send(customCommand: 0xCF)
        case .custom(let value):
            send(command: .SetContrast)
            send(customCommand: value)
        }
    }
    
    public func turn(_ state: State) {
        switch state {
        case .on:
            send(command: .DisplayOn)
        case .off:
            send(command: .DisplayOff)
        }
    }
    
}

//Extension for handling data transfers to display
extension display {
    func send(command: Command) {
        i2c.writeByte(self.address, command: 0b00000000, value: command.rawValue) //Co=0 D/C#=0
    }
    
    func send(customCommand: UInt8) {
        i2c.writeByte(self.address, command: 0b00000000, value: customCommand) //Co=0 D/C#=0
    }
    
    func sendBuffer() {
        for pageColumn in buffer {
            i2c.writeByte(self.address, command: 0b01000000, value: pageColumn) //Co=0 D/C#=1
        }
    }
    
}
