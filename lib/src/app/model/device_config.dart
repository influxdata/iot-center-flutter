class DeviceConfig {
  String influxUrl = '';
  String influxOrg = '';
  String influxToken = '';
  String influxBucket = '';
  String createdAt = '';
  String id = '';
  String type = '';

  DeviceConfig();

  DeviceConfig.withParams(this.id, this.createdAt, this.influxOrg,
      this.influxUrl, this.influxBucket, this.influxToken, this.type);

  DeviceConfig.fromJson(Map<String, dynamic> json) {
    influxUrl = json['influx_url'];
    influxOrg = json['influx_org'];
    influxToken = json['influx_token'];
    influxBucket = json['influx_bucket'];
    createdAt = json['createdAt'];
    id = json['id'];
  }

  void fromJson(Map<String, dynamic> json) {
    influxUrl = json['influx_url'];
    influxOrg = json['influx_org'];
    influxToken = json['influx_token'];
    influxBucket = json['influx_bucket'];
    createdAt = json['createdAt'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() => {
        'influx_url': influxUrl,
        'influx_org': influxOrg,
        'influx_token': influxToken,
        'influx_bucket': influxBucket,
        'createdAt': createdAt,
        'id': id,
      };
}

