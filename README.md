# SwiftyOLED

A Swift library for OLED displays based on SSD1306 and SSD1305 drivers.
It is just a set of functions for handling mentioned aboved drivers.
It is __not__ a graphics library. For that I would like to recommend a [SwiftyGFX](https://github.com/3Qax/SwiftyGFX), which I will be using here as an example. However you are free to use your own.

## Warning ⚠️

This library is under development. There wasn't even first release.

## Getting Started 💡

### Prerequisites
* Wire the display
* Create new project with SwiftPM like `swift package init --type executable`
* Add the following packages as your dependencies in your Swift package manifest file aka __Package.swift__ like
```swift
.package(url: "https://github.com/3Qax/SwiftyOLED.git", from: "1.0.0"),
.package(url: "https://github.com/3Qax/SwiftyGFX.git", from: "1.0.0"),
.package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
```
* Make sure you know to which I2C interface you have wired the display
* Make sure you are aware of a I2C address of display module you have. For most cases it will be 0x3C or 0x3D. If you are unsure run `sudo apt-get install i2c-tools && sudo i2cdetect -y 1`

### Code

Paste the following code into your source file, which most likely will be __main.swift__. Change I2C Interface and I2C address if needed.

```swift
import SwiftyOLED
import SwiftyGFX
import SwiftyGPIO

let i2cs = SwiftyGPIO.hardwareI2Cs(for: .RaspberryPiPlusZero)!
// Make sure you entered a correct parameters below
let myOLED = OLED(connectedTo: i2cs[1], at: 0x3C, width: 128, height: 32)

let myText = Text("Hello world!", font: "/home/pi/myOLED/Arial.ttf")

myOLED.draw(points: myText.generatePointsForDrawing())
myOLED.display()
```

### Result

Just do `swift build` and `swift run`. You should see:
![Image of Raspberry Pi with PiOLED connected to it on which "Hello world!" is visible](https://raw.githubusercontent.com/3Qax/SwiftyOLED/develop/Examples/hello%20world/result.jpg)
That's all. It's really that simple!

## Usage 🛠

TODO: provide list and description of core function here

## Performance 💨

TODO: provide valueable info here

## Contributing 🤝

Any suggestions and contributions are welcome, as long as they are up to scratch.

## Acknowledgments 📣

* Big inspiration and a lot of knowledge was taken from a [Adafruit CircuitPython library for SSD1306](https://github.com/adafruit/Adafruit_CircuitPython_SSD1306)
* This library use, require and rely on [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO)

## Datasheets 📚

- [SSD1306 ](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf)
- [UG-2832HSWEG02](https://cdn-shop.adafruit.com/datasheets/UG-2832HSWEG02.pdf)
