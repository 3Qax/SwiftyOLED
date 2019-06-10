import SwiftyOLED
import SwiftyGPIO



let i2cs = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPiPlusZero)!
let myOLED = display(on: i2cs[1])

func drawHearts() {
    var i: UInt8 = 0
    while i<=127-12 {
        myOLED.drawPixel(x: i+2, y: 0)
        myOLED.drawPixel(x: i+3, y: 0)
        myOLED.drawPixel(x: i+4, y: 0)
        myOLED.drawPixel(x: i+8, y: 0)
        myOLED.drawPixel(x: i+9, y: 0)
        myOLED.drawPixel(x: i+10, y: 0)
        myOLED.drawPixel(x: i+1, y: 1)
        myOLED.drawPixel(x: i+5, y: 1)
        myOLED.drawPixel(x: i+7, y: 1)
        myOLED.drawPixel(x: i+11, y: 1)
        myOLED.drawPixel(x: i+0, y: 2)
        myOLED.drawPixel(x: i+6, y: 2)
        myOLED.drawPixel(x: i+12, y: 2)
        myOLED.drawPixel(x: i+0, y: 3)
        myOLED.drawPixel(x: i+12, y: 3)
        myOLED.drawPixel(x: i+0, y: 4)
        myOLED.drawPixel(x: i+12, y: 4)
        myOLED.drawPixel(x: i+0, y: 5)
        myOLED.drawPixel(x: i+12, y: 5)
        myOLED.drawPixel(x: i+1, y: 6)
        myOLED.drawPixel(x: i+11, y: 6)
        myOLED.drawPixel(x: i+2, y: 7)
        myOLED.drawPixel(x: i+10, y: 7)
        myOLED.drawPixel(x: i+3, y: 8)
        myOLED.drawPixel(x: i+9, y: 8)
        myOLED.drawPixel(x: i+4, y: 9)
        myOLED.drawPixel(x: i+8, y: 9)
        myOLED.drawPixel(x: i+5, y: 10)
        myOLED.drawPixel(x: i+7, y: 10)
        myOLED.drawPixel(x: i+6, y: 11)
        i += 14
    }
}

drawHearts()
myOLED.display()



































