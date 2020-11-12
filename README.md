# AVR-in-FPGA-Emulator-Debugger

This is an AVR architecture design with most of the neccesary intructions to run any Arduino program.
It also contains a UART bootloader, and fully featured debugger with step by step instructions, breakpoints and real-time register visualization.

This project is currently abandoned, but in its current state it should work on most Intel/Altera FPGAs.
90% of the basic instruction set has been implemented, more than enough to run any "Arduino" compiled programs.

Specialized HW blocks like DMA inputs/outputs and timer prescaling are not implemented.

[![Product Name Screen Shot][screenshot]](https://example.com)

<!-- GETTING STARTED -->
## Getting Started

To get a local copy of the project and follow these steps.

1. Install Quartus (V13.1 or newer)

2. Build the Quartus project and flash the FPGA

3. Connect the computer to the FPGA with a USART adapter (By default to pins GPIO0 (RX) and GPIO1 (TX))

4. Start the dektop app to upload code / debug the running code.

<!-- ROADMAP -->
## Roadmap
This project has been abandoned as of right now but it is in a "usable" state. There is a decent chance that I will come back to it in the near future, but no guarantees are given.




<!-- CONTRIBUTING -->
## Contributing

Feel free to contribute to the project. Any changes you propose will be quickly reviewed but NOT tested.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->
## License

Distributed under the MIT License.

<!-- CONTACT -->
## Contact

Alejandro Cabrerizo - [@alecamaracm](https://twitter.com/alecamaracm) - [alecamar] AT [hotmail.es]

Project Link: [https://github.com/alecamaracm/AVR-in-FPGA-Emulator-Debugger](https://github.com/alecamaracm/AVR-in-FPGA-Emulator-Debugger)


<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* To [Peter Jamieson](https://twitter.com/peterajamieson), for being an awesome professor and introducing me to the world of digital systems.]

[screenshot]: images/debugger.png
