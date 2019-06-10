import SwiftyOLED
import SwiftyGPIO
#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif



let i2cs = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPiPlusZero)!
let myOLED = display(on: i2cs[1])


myOLED.draw(Square(x: 0, y: 0, sideSize: 31))
myOLED.draw(Circle(x: 32+5, y: 0, radius: 15))
myOLED.draw(Rectangle(x: 32+5+32+5, y: 0, a: 53, b: 31))
myOLED.display()




































