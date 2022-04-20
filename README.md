<div style="max-width: 1200px; min-width: 600px; font-size: 18px; background-color: #FAFAFAFF; color: #020A47FF; margin: auto; padding: 50px;">


# IoT Center <span style="color: #d30971;"> Demo.</span> Build on  <span style="color: #d30971;"> InfluxDB.</span>

This demo was designed to display data from Devices connected to IoT Center. Application is using InfluxDB v2 to store 
the data, Telegraf, Iot Center Demo and MQTT.



<img align="right" src="assets/images/demo-editable.png" alt="drawing" width="25%" style="margin-left: 15px; margin-top: 30px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px #A4A4A4FF);">
<img align="right" src="assets/images/demo.png" alt="drawing" width="25%" style="margin-top: 30px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px #A4A4A4FF);">

## Features

- data visualizations in gauge or simple chart
- editable charts parameters
- customizable dashboard - adding and deleting charts
- displaying device info and measurements
- write testing data
- automatic registration of devices in InfluxDB

## Getting Started

### Prerequisites
- Flutter - [Install Flutter](https://docs.flutter.dev/get-started/install), 
[online documentation](https://flutter.dev/docs)
- Docker - [Get started with docker](https://www.docker.com/get-started)
- IoT Center v2 with following ports - [IotCenter on GitHub](https://github.com/bonitoo-io/iot-center-v2)
    - 1883 (mqtt broker)
    - 8086 (influxdb 2.0 OSS)
    - 5000, 3000 nodejs server and UI app
    
For start of the latest version IoT Center you can use:
```bash
docker-compose up
open http://localhost:5000
```

### Device Registration

On [IoT Center](http://localhost:5000/) go to [Device Registrations](http://localhost:5000/devices) and click Register
to add a new device. Enter device id "virtual_device" and click to Register for create.

<img src="assets/images/iot-center-add-device.png" alt="drawing" style="border-radius: 10px; filter: drop-shadow(1px 5px 5px #A4A4A4FF);"/>

 
## Run Application

<img align="right" src="assets/images/demo-editable.png" alt="drawing" width="250px" style="margin-left: 5px; margin-top: 30px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px #A4A4A4FF);">

### Dashboard page

####AppBar
App bar on this screen contains basic functions:

- <img src="assets/images/lock_white_24dp.svg"/>/<img src="assets/images/lock_open_white_24dp.svg"/>
display/hide buttons for charts editing and add new chart button
- <img src="assets/images/autorenew_white_24dp.svg"/>
    refresh all charts
- <img src="assets/images/settings_white_24dp.svg"/> settings page with device info and IoT Center url settings 

On appbar drop down lists you can change device and time range for displaying data. After select device/time range
are data automatically refreshed.

#### Charts ListView



### Settings page


### Add chart page

<br clear="right"/>




</div>

