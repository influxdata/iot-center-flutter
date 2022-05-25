class Device {
  String influxUrl = '';
  String influxOrg = '';
  String influxToken = '';
  String influxBucket = '';
  String createdAt = '';
  String id = '';
  String key = '';

  String get tokenSubstring => influxToken.toString().substring(0, 3) + "...";

  Device(this.id, this.createdAt, this.key, this.influxOrg,
      this.influxUrl, this.influxBucket, this.influxToken);

}
