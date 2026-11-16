class Block {
  const Block({
    required this.code,
    required this.societyId,
    this.description = '',
  });

  final String code;
  final String societyId;
  final String description;
}