// History ki ek line (kisi plot par hua ek kaam).
class PlotEvent {
  const PlotEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.by,
    required this.createdAt,
  });

  final String id;

  // created, edited, hold, booked, allotted, possession, blocked, released,
  // payment, payment_reversed
  final String type;
  final String title;
  final String detail;

  // Kis user ki email ne ye kaam kiya.
  final String by;
  final DateTime createdAt;
}