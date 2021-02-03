import SwiftyGPIO



public final class OLED  {
    
    private let i2c: I2CInterface
    private let address: Int
    private let width: Int
    private let height: Int
    private var buffer: Array<UInt8>
    
    public private(set) var isInverted: Bool   = false
    public private(set) var isOn: Bool         = true
    
    public enum Brightness {
        case dimmed
        case bright
        case custom(value: UInt8)
    }
    
    public enum State {
        case on
        case off
    }
    
    
    
    public init(connectedTo interface: I2CInterface, at address: Int, width: Int, height: Int) {
        
        guard interface.isReachable(address) else {
            fatalError("""
                Can not reach display at given interface and address!
                Make sure that those are correct and the everything is wired correctly!
                """)
        }
        self.i2c = interface
        self.address = address
        
        guard width > 0 else { fatalError("Width have to be higher than 0!") }
        guard width <= 128 else { fatalError("SSD1306 driver does not support widths bigger than 128") }
        self.width = width
        
        guard height > 0 else { fatalError("Height have to be higher than 0!") }
        guard height <= 64 else { fatalError("SSD1306 driver does not support heights bigger than 64") }
        self.height = height
        
        self.buffer = Array<UInt8>(repeating: 0, count: Int(width*(height/8)))
        initialization()
    }
    
    //This method MUST be called when initialazing
    //It performs neccessary setup
    //Please refer to page 10 (section 4.4) of UG-2832HSWEG02 datasheet for more info.
    internal func initialization() {
        self.turn(.off)
        send(command: .SetDisplayClockDiv)
        send(customCommand: 0x80)                                  // the suggested ratio 0x80
        send(command: .SetMultiplex)
        send(customCommand: height == 32 ? 0x1F : 0x3F) // height - 1
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
        send(customCommand: height == 32 ? 0x02 : 0x12)
        self.set(brightness: .custom(value: UInt8(0x8F)))
        send(command: .SetPrecharge)
        send(customCommand: 0xF1)
        send(command: .SetVComDetect)
        send(customCommand: 0x40)
        send(command: .DisplayAllOnResume)
        send(command: .NormalDisplay)
        self.turn(.on)
    }
    
    //Makes point (tuplet of x and y coordinates) white
    //Drawing outside screen does not fail
    public func draw(point: (Int, Int)) {
        //if given point is in display's range draw it
        if point.0 >= 0 && point.0 <= width-1
        && point.1 >= 0 && point.1 <= height-1 {
            buffer[Int(point.1/8)*width+Int(point.0)] |=  1<<(point.1%8)
        }
    
    }
    
    //Makes points (arrary of tuplets (x and y coordinates)) white
    //by calling draw(point:_) for each point
    public func draw(points: [(Int, Int)]) {
        for point in points {
            // point.0 is x of point
            // point.1 is y of point
            self.draw(point: (point.0, point.1))
        }
        
    }
    
    //Makes the entire buffer white
    public func fill() {
        buffer = Array<UInt8>(repeating: UInt8.max, count: width*(height/8))
    }
    
    //Makes the entire buffer black
    public func clear() {
        buffer = Array<UInt8>(repeating: 0, count: width*(height/8))
    }
    
    //Makes data from buffer appear on physical display
    public func display() {
        send(command: Command.ColumnAddr)
        send(customCommand: 0)
        send(customCommand: UInt8(width-1))
        send(command: Command.PageAddr)
        send(customCommand: 0)
        send(customCommand: UInt8((height/8)-1))
        sendBuffer()
    }
    
    //Inverts display's interpretation of the buffer
    //What previously was black will be white and the other way around
    public func set(inversion: Bool) {
        if inversion {
            send(command: .InvertDisplay)
            self.isInverted = true
        } else {
            send(command: .NormalDisplay)
            self.isInverted = false
        }
    }
    
    public func set(brightness: Brightness) {
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
    
    public func turn(_ designatedState: State) {
        switch designatedState {
        case .on:
            send(command: .DisplayOn)
            self.isOn = true
        case .off:
            send(command: .DisplayOff)
            self.isOn = false
        }
    }
    
}

//Extension defining commands and methods to send them to display
extension OLED {
    
    internal enum Command: UInt8 {
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
    
    internal func send(command: Command) {
        i2c.writeByte(self.address, command: 0b00000000, value: command.rawValue) //Co=0 D/C#=0
    }
    
    internal func send(customCommand: UInt8) {
        i2c.writeByte(self.address, command: 0b00000000, value: customCommand) //Co=0 D/C#=0
    }
}

//Extension for sending buffer to display
extension OLED {

    //This method is slow, use it only when neccessary!
    //Usage of sendBuffer() is higly recommended
    internal func sendBufferByteByByte() {
        for pageColumn in buffer {
            i2c.writeByte(self.address, command: 0b01000000, value: pageColumn) //Co=0 D/C#=1
        }
    }
    
    internal func sendBuffer() {
        
        //send packages of 32 Bytes, which is I2C max number of bytes send at once
        let numberOfFullPackets = buffer.count/32
        for i in 1...numberOfFullPackets {
            i2c.writeI2CData(self.address, command: 0b01000000, values: Array(buffer[(i-1)*32...(i*32)-1])) //Co=0 D/C#=1
        }
        
        //if there aren't enought bytes left to form a full (32 Bytes) package send them
        if numberOfFullPackets*32 != buffer.count {
            i2c.writeI2CData(self.address, command: 0b01000000, values: Array(buffer[numberOfFullPackets*32...buffer.count-1])) //Co=0 D/C#=1
        }
    }
    
}
