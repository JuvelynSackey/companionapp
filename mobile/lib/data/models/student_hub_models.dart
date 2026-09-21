/// Local static fixture + local-only mutable models for the Student Hub
/// (shuttles/trotro, MoMo dues, lost & found).
/// No backend table exists for any of this (see docs/phase-2-plan.md) — dues
/// and lost & found reports are simulated, per-device state, never real
/// payments or a shared feed.
class ShuttleRoute {
  const ShuttleRoute({
    required this.id,
    required this.routeName,
    required this.routeCode,
    required this.fromStop,
    required this.toStop,
    required this.viaStops,
    required this.fareGhs,
    required this.nextArrivalMinutes,
    required this.busNumberPlate,
    required this.driverName,
    required this.driverPhone,
    required this.totalSeats,
    required this.seatsAvailable,
    required this.status,
    required this.operatingHours,
  });

  final String id;
  final String routeName;
  final String routeCode;
  final String fromStop;
  final String toStop;
  final List<String> viaStops;
  final double fareGhs;
  final int nextArrivalMinutes;
  final String busNumberPlate;
  final String driverName;
  final String driverPhone;
  final int totalSeats;
  final int seatsAvailable;
  final String status;
  final String operatingHours;

  double get occupancyRatio => 1 - (seatsAvailable / totalSeats);
}

enum DueCategory { departmentDues, hallDues, srcLevy, transcriptAdmin, examResit }

extension DueCategoryLabel on DueCategory {
  String get label => switch (this) {
        DueCategory.departmentDues => 'Department Dues',
        DueCategory.hallDues => 'Hall Dues',
        DueCategory.srcLevy => 'SRC Levy',
        DueCategory.transcriptAdmin => 'Transcript/Admin',
        DueCategory.examResit => 'Exam Resit',
      };
}

class CampusDue {
  const CampusDue({
    required this.id,
    required this.title,
    required this.category,
    required this.amountGhs,
    required this.dueDate,
    required this.description,
  });

  final String id;
  final String title;
  final DueCategory category;
  final double amountGhs;
  final String dueDate;
  final String description;
}

enum MoMoProvider { mtnMomo, telecelCash, atMoney }

extension MoMoProviderLabel on MoMoProvider {
  String get label => switch (this) {
        MoMoProvider.mtnMomo => 'MTN MoMo',
        MoMoProvider.telecelCash => 'Telecel Cash',
        MoMoProvider.atMoney => 'AT Money',
      };
}

/// A simulated receipt only — see the "SIMULATED PAYMENT" badge everywhere
/// this is shown. No real payment gateway is wired up.
class MoMoReceipt {
  const MoMoReceipt({
    required this.transactionRef,
    required this.dueId,
    required this.itemTitle,
    required this.amountGhs,
    required this.payerName,
    required this.studentId,
    required this.momoNumber,
    required this.provider,
    required this.timestamp,
  });

  factory MoMoReceipt.fromJson(Map<String, dynamic> json) => MoMoReceipt(
        transactionRef: json['transactionRef'] as String,
        dueId: json['dueId'] as String,
        itemTitle: json['itemTitle'] as String,
        amountGhs: (json['amountGhs'] as num).toDouble(),
        payerName: json['payerName'] as String,
        studentId: json['studentId'] as String,
        momoNumber: json['momoNumber'] as String,
        provider: MoMoProvider.values.byName(json['provider'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  final String transactionRef;
  final String dueId;
  final String itemTitle;
  final double amountGhs;
  final String payerName;
  final String studentId;
  final String momoNumber;
  final MoMoProvider provider;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'transactionRef': transactionRef,
        'dueId': dueId,
        'itemTitle': itemTitle,
        'amountGhs': amountGhs,
        'payerName': payerName,
        'studentId': studentId,
        'momoNumber': momoNumber,
        'provider': provider.name,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum LostFoundStatus { lost, found }

enum LostFoundCategory { idAndCards, calculatorsAndElectronics, bagsAndWallets, keys, booksAndNotes, other }

extension LostFoundCategoryLabel on LostFoundCategory {
  String get label => switch (this) {
        LostFoundCategory.idAndCards => 'ID & Cards',
        LostFoundCategory.calculatorsAndElectronics => 'Calculators & Electronics',
        LostFoundCategory.bagsAndWallets => 'Bags & Wallets',
        LostFoundCategory.keys => 'Keys',
        LostFoundCategory.booksAndNotes => 'Books & Notes',
        LostFoundCategory.other => 'Other',
      };
}

class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.campusLocation,
    required this.dateReported,
    required this.reporterName,
    required this.contactPhone,
    required this.description,
    this.claimInstructions,
    this.rewardGhs,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) => LostFoundItem(
        id: json['id'] as String,
        title: json['title'] as String,
        category: LostFoundCategory.values.byName(json['category'] as String),
        status: LostFoundStatus.values.byName(json['status'] as String),
        campusLocation: json['campusLocation'] as String,
        dateReported: json['dateReported'] as String,
        reporterName: json['reporterName'] as String,
        contactPhone: json['contactPhone'] as String,
        description: json['description'] as String,
        claimInstructions: json['claimInstructions'] as String?,
        rewardGhs: (json['rewardGhs'] as num?)?.toDouble(),
      );

  final String id;
  final String title;
  final LostFoundCategory category;
  final LostFoundStatus status;
  final String campusLocation;
  final String dateReported;
  final String reporterName;
  final String contactPhone;
  final String description;
  final String? claimInstructions;
  final double? rewardGhs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'status': status.name,
        'campusLocation': campusLocation,
        'dateReported': dateReported,
        'reporterName': reporterName,
        'contactPhone': contactPhone,
        'description': description,
        'claimInstructions': claimInstructions,
        'rewardGhs': rewardGhs,
      };
}
