import SwiftyOLED
import SwiftyGFX
import SwiftyGPIO

let i2cs = SwiftyGPIO.hardwareI2Cs(for: .RaspberryPiPlusZero)!
// Make sure you entered a correct parameters below
let myOLED = OLED(connectedTo: i2cs[1], at: 0x3C, width: 128, height: 32)

let myText = Text("Hello world!")

myOLED.draw(points: myText.generatePointsForDrawing())
myOLED.display()
