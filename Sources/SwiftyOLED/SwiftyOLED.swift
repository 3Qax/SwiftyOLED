import SwiftyGPIO
#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif



public final class OLED  {
    
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
    
    public init(connectedTo interface: I2CInterface, at address: Int) {
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
    
    //Draw objet (arrary of tuplets (x and y points)) at given origin
    //Drawing outside screen is possible
    public func draw(points: [(Int, Int)], at origin: (Int, Int) = (0, 0)) {
        
        // origin.0 is x of origin
        // origin.1 is y of origin
        for point in points {
            // point.0 is x of point
            // point.1 is y of point
            
            //if given point is in display's range draw it
            if point.0+origin.0 >= 0 && point.0+origin.0 <= 127
            && point.1+origin.1 >= 0 && point.1+origin.1 <= 31 {
                self.drawPixel(x: UInt8(point.0+origin.0), y: UInt8(point.1+origin.1))
            }
        }
        
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
extension OLED {
    func send(command: Command) {
        i2c.writeByte(self.address, command: 0b00000000, value: command.rawValue) //Co=0 D/C#=0
    }
    
    func send(customCommand: UInt8) {
        i2c.writeByte(self.address, command: 0b00000000, value: customCommand) //Co=0 D/C#=0
    }
    
    //This method is slow, use it only when neccessary!
    //Usage of sendBuffer() is higly recommended
    func sendBufferByteByByte() {
        for pageColumn in buffer {
            i2c.writeByte(self.address, command: 0b01000000, value: pageColumn) //Co=0 D/C#=1
        }
    }
    
    func sendBuffer() {
        
        //send packages of 32 Bytes, which is I2C max number of bytes send at once
        let numberOfFullPackets = buffer.count/32
        for i in 1...numberOfFullPackets {
            i2c.writeI2CData(self.address, command: 0b01000000, values: Array(buffer[(i-1)*32...(i*32)-1]))
        }
        
        //if there aren't enought bytes left to form a full (32 Bytes) package send them
        if numberOfFullPackets*32 != buffer.count {
            i2c.writeI2CData(self.address, command: 0b01000000, values: Array(buffer[numberOfFullPackets*32...buffer.count-1]))
        }
    }
    
}
