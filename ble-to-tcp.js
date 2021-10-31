'use strict'
const noble = require('noble-mac')
const TARGET_LOCAL_NAME = 'optoSense'
const net = require('net')
const client = new net.Socket()
var ready_to_write = false

client.connect(2337, '127.0.0.1', () => {
  console.log('Connected')
  ready_to_write = true
  //!!!!!!!!!!!!!!!For testing only! comment this out!!!!!!!!!
  // setInterval(() => {
  //   client.write('test')
  // }, 1000)
})

noble.on('stateChange', function(state) {
  if (state === 'poweredOn') {
    noble.startScanning();
    console.log('poweredOn')
  } else {
    noble.stopScanning();
  }
});

noble.on('discover', function(peripheral) {
  console.log(`peripheral discovered ( ${peripheral.id} with addr <${peripheral.address}, ${peripheral.addressType}> connectable ${peripheral.connectable} RSSI: ${peripheral.rssi} local name: ${peripheral.advertisement.localName})`)
  if (peripheral.advertisement.localName === TARGET_LOCAL_NAME){
    console.log('Found target!')
    noble.stopScanning();
    peripheral.connect(function(error) {
      peripheral.discoverServices([], (err, services) => {
        if (err) {
          console.log(err)
        }
        if (services[0].uuid === '6e400001b5a3f393e0a9e50e24dcca9e'){
          services[0].discoverCharacteristics([], function(error, characteristics) {
            if (characteristics[1].uuid === '6e400003b5a3f393e0a9e50e24dcca9e'){              
              console.log("found characteristics")
              characteristics[1].notify(true, function(error) {
                console.log('notification on');
              })
              characteristics[1].on('data', (data, isNotification) => {
                var uint8array = Uint8Array.from(data)
                // console.log(uint8array)
                if (ready_to_write) {
                  client.write(uint8array[0] + ' '
                    + uint8array[1] + ' '
                    + uint8array[2] + ' '
                    + uint8array[3] + ' '
                    + uint8array[4] + ' '
                    + uint8array[5] + ' '
                    + uint8array[6] + ' '
                    + uint8array[7] + ' '
                    + uint8array[8] + ' '
                    + uint8array[9] + ' '
                    + uint8array[10] + ' '
                    + uint8array[11] + ' '
                    + uint8array[12] + ' '
                    + uint8array[13] + ' '
                    + uint8array[14] + ' '
                    + uint8array[15] + ' '
                    + uint8array[16] + ' '
                    + uint8array[17] + ' '
                    + uint8array[18] + ' '
                    + uint8array[19] + ' '
                    + uint8array[20] + ' '
                    + uint8array[21] + ' '
                    + uint8array[22] + ' '
                    + uint8array[23] + ' '
                    + uint8array[24] + ' '
                    + uint8array[25] + ' '
                    + uint8array[26] + ' '
                    + uint8array[27] + ' '
                    + uint8array[28] + ' '
                    + uint8array[29] + ' '
                    + uint8array[30] + ' '
                    + uint8array[31] + ' '
                    + uint8array[32] + ' '
                    + uint8array[33] + ' '
                    + uint8array[34] + ' '
                    + uint8array[35] + ' '
                    + uint8array[36] + ' '
                    + uint8array[37] + ' '
                    + uint8array[38] + ' '
                    + uint8array[39] + ' '
                    + uint8array[40] + ' '
                    + uint8array[41] + ' '
                    + uint8array[42] + ' '
                    + uint8array[43] + ' '
                    + uint8array[44] + ' '
                    + uint8array[45] + ' '
                    + uint8array[46] + ' '
                    + uint8array[47] + ' '
                    + uint8array[48] + ' '
                    + uint8array[49] + ' '
                    + uint8array[50] + ' '
                    + uint8array[51] + ' '
                    + uint8array[52] + ' '
                    + uint8array[53] + ' '
                    + uint8array[54] + ' '
                    + uint8array[55] + ' '
                    + uint8array[56] + ' '
                    + uint8array[57] + ' '
                    + uint8array[58] + ' '
                    + uint8array[59] + ' '
                    + uint8array[60] + ' '
                    + uint8array[61] + ' '
                    + uint8array[62] + ' '
                    + uint8array[63])
                }                // var float32Array = Float32Array.from(data)
                // console.log(float32Array)
                // if (ready_to_write) {
                //   client.write(float32Array[0] + ' '
                //     + float32Array[1] + ' '
                //     + float32Array[2] + ' '
                //     + float32Array[3] + ' '
                //     + float32Array[4] + ' '
                //     + float32Array[5] + ' '
                //     + float32Array[6] + ' '
                //     + float32Array[7] + ' '
                //     + float32Array[8] + ' '
                //     + float32Array[9] + ' '
                //     + float32Array[10] + ' '
                //     + float32Array[11] + ' '
                //     + float32Array[12] + ' '
                //     + float32Array[13] + ' '
                //     + float32Array[14] + ' '
                //     + float32Array[15] + ' '
                //     + float32Array[16] + ' '
                //     + float32Array[17] + ' '
                //     + float32Array[18] + ' '
                //     + float32Array[19] + ' '
                //     + float32Array[20] + ' '
                //     + float32Array[21] + ' '
                //     + float32Array[22] + ' '
                //     + float32Array[23] + ' '
                //     + float32Array[24] + ' '
                //     + float32Array[25] + ' '
                //     + float32Array[26] + ' '
                //     + float32Array[27] + ' '
                //     + float32Array[28] + ' '
                //     + float32Array[29] + ' '
                //     + float32Array[30] + ' '
                //     + float32Array[31] + ' '
                //     + float32Array[32] + ' '
                //     + float32Array[33] + ' '
                //     + float32Array[34] + ' '
                //     + float32Array[35] + ' '
                //     + float32Array[36] + ' '
                //     + float32Array[37] + ' '
                //     + float32Array[38] + ' '
                //     + float32Array[39] + ' '
                //     + float32Array[40] + ' '
                //     + float32Array[41] + ' '
                //     + float32Array[42] + ' '
                //     + float32Array[43] + ' '
                //     + float32Array[44] + ' '
                //     + float32Array[45] + ' '
                //     + float32Array[46] + ' '
                //     + float32Array[47] + ' '
                //     + float32Array[48] + ' '
                //     + float32Array[49] + ' '
                //     + float32Array[50] + ' '
                //     + float32Array[51] + ' '
                //     + float32Array[52] + ' '
                //     + float32Array[53] + ' '
                //     + float32Array[54] + ' '
                //     + float32Array[55] + ' '
                //     + float32Array[56] + ' '
                //     + float32Array[57] + ' '
                //     + float32Array[58] + ' '
                //     + float32Array[59] + ' '
                //     + float32Array[60] + ' '
                //     + float32Array[61] + ' '
                //     + float32Array[62] + ' '
                //     + float32Array[63])
                // }
              });    
            }
          });
        }
      });
    });
  }
});
