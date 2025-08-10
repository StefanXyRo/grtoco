enum ReportedItemType { post, comment, user }
enum ReportStatus { pending, resolved }

class Report {
  final String reportId;
  final String itemId;
  final ReportedItemType itemType;
  final String reporterId;
  final String reason;
  final ReportStatus status;

  Report({
    required this.reportId,
    required this.itemId,
    required this.itemType,
    required this.reporterId,
    required this.reason,
    this.status = ReportStatus.pending,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as String,
      itemId: json['itemId'] as String,
      itemType: ReportedItemType.values.firstWhere(
        (e) => e.toString() == 'ReportedItemType.${json['itemType']}',
        orElse: () => ReportedItemType.post,
      ),
      reporterId: json['reporterId'] as String,
      reason: json['reason'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${json['status']}',
        orElse: () => ReportStatus.pending,
      ),
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
