enum ItemType { post, comment, user }
enum ReportStatus { pending, resolved }

class Report {
  final String reportId;
  final String itemId;
  final ItemType itemType;
  final String reporterId;
  final String reason;
  final ReportStatus status;

  Report({
    required this.reportId,
    required this.itemId,
    required this.itemType,
    required this.reporterId,
    required this.reason,
    required this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as String,
      itemId: json['itemId'] as String,
      itemType: ItemType.values.firstWhere((e) => e.toString() == 'ItemType.${json['itemType']}'),
      reporterId: json['reporterId'] as String,
      reason: json['reason'] as String,
      status: ReportStatus.values.firstWhere((e) => e.toString() == 'ReportStatus.${json['status']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'itemId': itemId,
      'itemType': itemType.toString().split('.').last,
      'reporterId': reporterId,
      'reason': reason,
      'status': status.toString().split('.').last,
    };
  }
}
