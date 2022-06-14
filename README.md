<div style="max-width: 1200px; min-width: 600px; font-size: 18px; margin: auto; padding: 50px;">


<h1>IoT Center <a style="color: #d30971 !important;"> Demo v2.</a> Build on <a style="color: #d30971 !important;"> InfluxDB.</a></h1>

This demo was designed to display data from Devices connected to IoT Center. Application is using InfluxDB v2 to store 
the data, Telegraf and MQTT.

<img align="right" src="assets/images/device-detail.png" alt="drawing" width="35%" style="margin-left: 30px;margin-top: 30px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

## Features

### Devices
- device registration in InfluxDB
- two types of device - virtual and mobile
- remove device from InfluxDB
- remove associated device data
- displaying device info and measurements
- data visualizations in gauge or simple chart
- can use different dashboards for one device
- write testing data to InfluxDB for virtual device
- write sensor data to InfluxDB for mobile device

### Dashboards
- dashboard registration in InfluxDB
- two types of dashboards - virtual or mobile
- pair dashboard with device
- editable charts parameters
- customizable - adding and deleting charts


## Getting Started

### Prerequisites
- Flutter - [Install Flutter](https://docs.flutter.dev/get-started/install), 
[online documentation](https://flutter.dev/docs)
- Docker - [Get started with docker](https://www.docker.com/get-started)
- **InfluxDB** with mosquitto and telegraf 
  - you need following ports: 
      - **1883** (mqtt broker)
      - **8086** (influxdb 2.0 OSS)
  - for start use docker-compose.yaml:
    ```bash
    docker-compose up
    ```

## Run Application

<img align="right" src="assets/images/home-page.png" alt="drawing" width="25%" style="margin-left: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

### Home page

#### AppBar
App bar on this screen contains basic functions:

- ![Lock](assets/images/icons/add_white_24dp.svg#gh-dark-mode-only)
  ![Lock](assets/images/icons/add_dark_24dp.svg#gh-light-mode-only)
  add new device
- ![Auto-renew](assets/images/icons/autorenew_white_24dp.svg#gh-dark-mode-only)
  ![Auto-renew](assets/images/icons/autorenew_dark_24dp.svg#gh-light-mode-only) 
refresh devices
- ![Settings](assets/images/icons/settings_white_24dp.svg#gh-dark-mode-only)
 ![Lock](assets/images/icons/settings_dark_24dp.svg#gh-light-mode-only) settings page 

#### Device ListView
Each device tile contains DeviceId and following actions:

- ![Settings](assets/images/icons/delete_white_24dp.svg#gh-dark-mode-only)![Lock](assets/images/icons/delete_dark_24dp.svg#gh-light-mode-only) for deleting device
- ![Lock](assets/images/icons/arrow_forward.svg#gh-dark-mode-only)
    ![Lock](assets/images/icons/arrow_forward_dark.svg#gh-light-mode-only)
    go to device page


<img align="right" src="assets/images/new-device.png" alt="drawing" width="25%" style="margin-left: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

#### Add Device

To `TextBox` enter device id, in `DropDownList` select type of device and click to Save for create. Device is automatically 
registered in InfluxDB - it's write as point via `WriteService` with its authorization.

Example of creating device point in InfluxDB - [createDevice](/lib/src/app/model/influx_model.dart#L525):
```dart
var writeApi = _influxDBClient.getWriteService();
var point = Point('deviceauth')
          .addTag('deviceId', deviceId)
          .addField('key', authorization.id)
          .addField('token', authorization.token);
writeApi.write(point);
```

Creating device IoT authorization via `AuthorizationsApi` - [_createIoTAuthorization](/lib/src/app/model/influx_model.dart#L593):
```dart
var authorizationApi = _influxDBClient.getAuthorizationsApi();
var permissions = [
  Permission(
          action: PermissionActionEnum.read,
          resource: Resource(
                  type: ResourceTypeEnum.buckets,
                  id: bucketId,
                  orgID: orgId,
                  org: org)),
  Permission(
          action: PermissionActionEnum.write,
          resource: Resource(
                  type: ResourceTypeEnum.buckets,
                  id: bucketId,
                  orgID: orgId,
                  org: org)),
];
AuthorizationPostRequest request = AuthorizationPostRequest(
        orgID: orgId,
        description: 'IoTCenterDevice: ' + deviceId,
        permissions: permissions);

authorizationApi.postAuthorizations(request);
```


#### Refresh Devices

Reload active devices (`_value` field cannot be empty) from InfluxDB using `QueryService` with following query - 
[fetchDevices](/lib/src/app/model/influx_model.dart#L94):
```sql
from(bucket: "${_influxDBClient.bucket}")
    |> range(start: -30d)
    |> filter(fn: (r) => r["_measurement"] == "deviceauth"
                     and r["_field"] == "key")
    |> last()
    |> filter(fn: (r) => r["_value"] != "")
```

<img align="right" src="assets/images/delete-device.png" alt="drawing" width="25%" style="margin-left: 15px; margin-bottom: 15px; border-radius: 10px; filter: drop-shadow(1px 5px 5px black);">

#### Delete Device

On each tile of device is ![Settings](assets/images/icons/delete_white_24dp.svg#gh-dark-mode-only)![Lock](assets/images/icons/delete_dark_24dp.svg#gh-light-mode-only) 
for deleting device. After clicking on it, there is confirmation dialog with `CheckBox` for choose deleting 
device with associated data - if it's checked, data are deleted too.

Example of deleting data via `DeleteService` - [deleteDevice](/lib/src/app/model/influx_model.dart#L644):
```dart
var deleteApi = _influxDBClient.getDeleteService();
if (deleteWithData) {
    await deleteApi.delete(
          predicate: 'clientId="$deviceId"',
          start: DateTime(1970).toUtc(),
          stop: DateTime.now().toUtc(),
          bucket: _influxDBClient.bucket,
          org: _influxDBClient.org);
}
```

After deleting device **isn't** remove from InfluxDB - in this case **deleting** is meaning **removing of device
authorization** and **IoT Authorization**.

Removed device has in InfluxDB empty fields `key` and `token`, it means, that device authorization was removed via 
`WriteService`- [_removeDeviceAuthorization](/lib/src/app/model/influx_model.dart#L674):
```dart
var writeApi = _influxDBClient.getWriteService();
var point = Point('deviceauth')
          .addTag('deviceId', deviceId)
          .addField('key', '')
          .addField('token', '');
writeApi.write(point);
```

IoT Authorization is also removed, in this case `AuthorizationsApi` is used - [_deleteIoTAuthorization](/lib/src/app/model/influx_model.dart#L715):
```dart
 var authorizationApi = _influxDBClient.getAuthorizationsApi();
 authorizationApi.deleteAuthorizationsID(key);
```






### Settings Page

#### Dashboards

#### Sensors

#### Influx settings


### Device Detail Page

#### Dashboard

Dashboard tab contains chart ListView - it's scrollable and contains two different types of charts - gauge and simple.
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


#### Device Detail

#### Measurements



<br clear="right"/>


</div>

