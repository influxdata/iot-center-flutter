<div style="max-width: 1200px; min-width: 600px; font-size: 18px; margin: auto; padding: 50px;">

<h1>IoT Center <a style="color: #d30971 !important;"> Demo.</a> Build on <a style="color: #d30971 !important;"> InfluxDB.</a></h1>

This demo was designed to display data from Devices connected to IoT Center. Application is using InfluxDB v2 to store 
the data, Telegraf, Iot Center Demo and MQTT.

<img align="right" src="assets/images/demo.png" alt="drawing" width="35%" style="margin-left: 30px;margin-top: 30px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

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
    - 5000 (IoT center)
    
For start of the latest version IoT Center you can use:
```bash
docker-compose up
open http://localhost:5000
```

### Device Registration

On [IoT Center](http://localhost:5000/) go to [Device Registrations](http://localhost:5000/devices) and click Register
to add a new device. Enter device id "virtual_device" and click to Register for create.

<img src="assets/images/iot-center-add-device.png" alt="drawing" style="border-radius: 10px; filter: drop-shadow(1px 5px 5px black);"/>

 
## Run Application

<img align="right" src="assets/images/demo-editable.png" alt="drawing" width="25%" style="margin-left: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

### Dashboard page

#### AppBar
App bar on this screen contains basic functions:

- ![Lock](assets/images/icons/lock_white_24dp.svg#gh-dark-mode-only)
![Lock](assets/images/icons/lock_dark_24dp.svg#gh-light-mode-only)/
![Lock open](assets/images/icons/lock_open_white_24dp.svg#gh-dark-mode-only)
![Lock open](assets/images/icons/lock_open_dark_24dp.svg#gh-light-mode-only)
display/hide buttons for charts editing and add new chart button
- ![Autorenew](assets/images/icons/autorenew_white_24dp.svg#gh-dark-mode-only)
  ![Autorenew](assets/images/icons/autorenew_dark_24dp.svg#gh-light-mode-only) 
refresh all charts
- ![Settings](assets/images/icons/settings_white_24dp.svg#gh-dark-mode-only)
 ![Lock](assets/images/icons/settings_dark_24dp.svg#gh-light-mode-only) settings page with device info and 
IoT Center url settings 

On appbar drop down lists you can change device and time range for displaying data. After select device/time range
are data automatically refreshed.

#### Charts ListView
Charts ListView is scrollable and contains two different types of charts - gauge and simple.
- Gauge chart display average of all values in selected time range
```sql
import "influxdata/influxdb/v1"
    from(bucket: "${_client.bucket}")
        |> range(start: $maxPastTime)
        |> filter(fn: (r) => r.clientId == "${_config.id}" 
                    and r._measurement == "environment" 
                    and r["_field"] == "$field")
        |> mean()
```
- Simple chart display average data for aggregate window
```sql
import "influxdata/influxdb/v1"
    from(bucket: "${_client.bucket}")
        |> range(start: $maxPastTime)
        |> filter(fn: (r) => r.clientId == "${_config.id}" 
                    and r._measurement == "environment" 
                    and r["_field"] == "$field")
        |> keep(columns: ["_value", "_time"])
        |> aggregateWindow(column: "_value", every: $aggregate, fn: mean)
```
<img align="left" src="assets/images/demo-edit-chart.png" alt="drawing" width="25%" style="margin-right: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

#### Edit Chart

Each chart in Charts ListView contains ![Settings](assets/images/icons/settings_white_24dp.svg#gh-dark-mode-only)
![Lock](assets/images/icons/settings_dark_24dp.svg#gh-light-mode-only) button (after unlock editing in AppBar). 
By clicking it, Edit Chart page is displayed. 

On this page chart can be deleted by clicking on ![Settings](assets/images/icons/delete_white_24dp.svg#gh-dark-mode-only)
![Lock](assets/images/icons/delete_dark_24dp.svg#gh-light-mode-only) in AppBar and after confirmation dialog.

DropDown list `Field:` gets values from influx by following query:
```sql
import "influxdata/influxdb/schema"
    schema.fieldKeys(
        bucket: "${_client.bucket}",
        predicate: (r) => r["_measurement"] == "environment" 
                      and r["clientId"] == "${_config.id}")
```
After updating chart are data automatically refreshed (only for updated chart).

**All changes in dashboard** - like add, delete and edit charts, are saved to system preferences after finish editing by 
clicking ![Lock open](assets/images/icons/lock_open_white_24dp.svg#gh-dark-mode-only)
![Lock open](assets/images/icons/lock_open_dark_24dp.svg#gh-light-mode-only) on Dashboard Page AppBar.

<img align="right" src="assets/images/demo-settings.png" alt="drawing" width="25%" style="margin-left: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

### Settings page

#### AppBar
App bar on this screen contains basic functions:

- ![Lock](assets/images/icons/add_white_24dp.svg#gh-dark-mode-only)
  ![Lock](assets/images/icons/add_dark_24dp.svg#gh-light-mode-only)
  add new device
- ![Autorenew](assets/images/icons/link_white_24dp.svg#gh-dark-mode-only)
  ![Autorenew](assets/images/icons/link_dark_24dp.svg#gh-light-mode-only)
  change IoT Center url (save to system preferences)

On appbar drop down lists you can change device - device configuration and device Measurements 
are automatically refreshed.

#### Device Configuration



### Add chart page

<br clear="right"/>




</div>

